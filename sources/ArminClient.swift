//
//  ArminClient.swift
//  Pods
//
//  Created by Cavan on 2023/10/30.
//

import Foundation

@objc open class ArminClient: NSObject {
    private lazy var sessions = [String: SessionManager]()    // Key: sessionId
    private lazy var retryHelpers = [String: ArRetryHelper]() // Key: sessionId
    
    private var taskId = 0
    
    private var afterQueue = DispatchQueue(label: "com.armin.retry.thread")
    
    public weak var logTube: ArLogTube?
    
    @objc public init(logTube: ArLogTube? = nil) {
        self.logTube = logTube
    }
    
    @objc public func objc_request(url: String,
                              headers: [String: String]?,
                              parameters: [String: Any]?,
                              method: ArHttpMethod,
                              event: String,
                              timeout: TimeInterval,
                              responseQueue: DispatchQueue,
                              retryCount: Int,
                              jsonSuccess: ArJsonCompletion?,
                              failure: ArErrorCompletion?) {
        let closure = ArSuccessCompletion.json { json in
            jsonSuccess?(json)
        }
        
        request(url: url,
                headers: headers,
                parameters: parameters,
                method: method,
                event: event,
                timeout: .custom(timeout),
                responseQueue: responseQueue,
                retryCount: retryCount,
                success: closure,
                failure: failure)
    }
    
    @objc public func objc_request(url: String,
                              headers: [String: String]?,
                              parameters: [String: Any]?,
                              method: ArHttpMethod,
                              event: String,
                              timeout: TimeInterval,
                              responseQueue: DispatchQueue,
                              retryCount: Int,
                              dataSuccess: ArDataCompletion?,
                              failure: ArErrorCompletion?) {
        let closure = ArSuccessCompletion.data { data in
            dataSuccess?(data)
        }
        
        request(url: url,
                headers: headers,
                parameters: parameters,
                method: method,
                event: event,
                timeout: .custom(timeout),
                responseQueue: responseQueue,
                retryCount: retryCount,
                success: closure,
                failure: failure)
    }
    
    @objc public func objc_request(url: String,
                              headers: [String: String]?,
                              parameters: [String: Any]?,
                              method: ArHttpMethod,
                              event: String,
                              timeout: TimeInterval,
                              responseQueue: DispatchQueue,
                              retryCount: Int,
                              success: ArCompletion?,
                              failure: ArErrorCompletion?) {
        let closure = ArSuccessCompletion.blank {
            success?()
        }
        
        request(url: url,
                headers: headers,
                parameters: parameters,
                method: method,
                event: event,
                timeout: .custom(timeout),
                responseQueue: responseQueue,
                retryCount: retryCount,
                success: closure,
                failure: failure)
    }
    
    public func test() {
        
    }
    
    public func request(url: String,
                        headers: [String: String]? = nil,
                        parameters: [String: Any]? = nil,
                        method: ArHttpMethod,
                        event: String,
                        timeout: ArRequestTimeout = .medium,
                        responseQueue: DispatchQueue = .main,
                        retryCount: Int = 0,
                        success: ArSuccessCompletion? = nil,
                        failure: ArErrorCompletion? = nil) {
        taskId += 1
        
        let sessionId = "\(event)-\(taskId)"
        
        let session = addSession(timeout: timeout.value,
                                 id: sessionId)
        
        let retry = addRetryHelper(id: sessionId,
                                   count: retryCount)
        
        privateRequest(session: session,
                       retry: retry,
                       url: url,
                       headers: headers,
                       parameters: parameters,
                       method: method,
                       event: event,
                       timeout: timeout,
                       responseQueue: responseQueue,
                       success: success,
                       failure: failure) { [weak self] in
            self?.removeSession(id: sessionId)
            self?.removeRetryHelper(id: sessionId)
        }
    }
    
    private func privateRequest(session: SessionManager,
                                retry: ArRetryHelper?,
                                url: String,
                                headers: [String: String]? = nil,
                                parameters: [String: Any]? = nil,
                                method: ArHttpMethod,
                                event: String,
                                timeout: ArRequestTimeout = .medium,
                                responseQueue: DispatchQueue = .main,
                                success: ArSuccessCompletion? = nil,
                                failure: ArErrorCompletion? = nil,
                                completion: @escaping ArExCompletion) {
        var extra = "url: \(url)"
        extra += ", headers: \(optionalDescription(headers))"
        extra += ", parameters: \(optionalDescription(parameters))"
        
        log(info: "http request, event: \(event)",
            extra: extra)
        
        let queue = responseQueue
        
        let request = createRequest(session: session,
                                    method: method,
                                    url: url,
                                    parameters: parameters,
                                    headers: headers)
        
        request.responseData(queue: queue) { [weak self] (dataResponse) in
            queue.async { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                
                strongSelf.handleResponse(response: dataResponse,
                                          url: url,
                                          event: event,
                                          success: success) { [weak retry] error in
                    
                    if let `retry` = retry, retry.ifNeedRetry() {
                        retry.perform { [weak self, weak retry] in
                            self?.privateRequest(session: session,
                                                 retry: retry,
                                                 url: url,
                                                 headers: headers,
                                                 parameters: parameters,
                                                 method: method,
                                                 event: event,
                                                 success: success,
                                                 failure: failure,
                                                 completion: completion)
                        }
                    } else {
                        failure?(error)
                    }
                }
            }
        }
    }
    
    private func createRequest(session: SessionManager,
                               method: ArHttpMethod,
                               url: String,
                               parameters: [String: Any]?,
                               headers: [String: String]?) -> DataRequest {
        var dataRequest: DataRequest
        
        if method == .get {
            var fullUrl = url
            
            if let parameters = parameters {
                fullUrl = urlAddParameters(url: url,
                                           parameters: parameters)
            }
            
            dataRequest = session.request(fullUrl,
                                          method: method.alType,
                                          encoding: method.alType.encoding,
                                          headers: headers)
        } else {
            dataRequest = session.request(url,
                                          method: method.alType,
                                          parameters: parameters,
                                          encoding: method.alType.encoding,
                                          headers: headers)
        }
        
        return dataRequest
    }
    
    private func handleResponse(response: DataResponse<Data>, url: String, event: String,
                                responseQueue: DispatchQueue = .main,
                                success: ArSuccessCompletion? = nil,
                                failure: ArErrorCompletion? = nil) {
        do {
            let data = try checkResponse(response)
            
            let info = "http request sunccessfully, event: \(event)"
            var extra = "url: \(url)"
            
            if let `success` = success {
                switch success {
                case .json(let closure):
                    let json = try data.json()
                    extra += ", response json: \(json.description)"
                    try closure(json)
                case .data(let closure):
                    try closure(data)
                case .blank(let closure):
                    try closure()
                }
            }
            
            log(info: info,
                extra: extra)
        } catch let error {
            var extra = "http request unsunccessfully, event: \(event)"
            extra += ", url: \(url)"
            
            log(error: error,
                extra: extra)
            
            failure?(error)
        }
    }
    
    private func checkResponse(_ response: DataResponse<Data>) throws -> Data {
        if let error = response.error {
            throw error
        }
        
        guard let statusCode = response.response?.statusCode else {
            throw NSError(code: -1,
                          message: "http code nil")
        }
        
        guard statusCode == 200 else {
            throw NSError(code: statusCode,
                          message: "http code error")
        }
        
        guard let data = response.data else {
            throw NSError(code: -1,
                          message: "http response data nil")
        }
        
        return data
    }
    
    func optionalDescription<T>(_ any: T?) -> String where T : CustomStringConvertible {
        if let `any` = any {
            return any.description
        } else {
            return "nil"
        }
    }
}

private extension ArminClient {
    func addSession(timeout: TimeInterval,
                    id: String) -> SessionManager {
        if let session = sessions[id] {
            return session
        } else {
            let configuration = URLSessionConfiguration.default
            configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
            configuration.timeoutIntervalForRequest = timeout
            
            let session = SessionManager(configuration: configuration)
            sessions[id] = session
            
            return session
        }
    }
    
    func removeSession(id: String) {
        sessions.removeValue(forKey: id)
    }
    
    func addRetryHelper(id: String,
                        count: Int) -> ArRetryHelper {
        let helper = ArRetryHelper(maxCount: count,
                                   queue: afterQueue)
        
        retryHelpers[id] = helper
        
        return helper
    }
    
    func removeRetryHelper(id: String) {
        retryHelpers.removeValue(forKey: id)
    }
    
    func urlAddParameters(url: String,
                          parameters: [String: Any]) -> String {
        var fullURL = url
        var index: Int = 0
        
        for (key, value) in parameters {
            if index == 0 {
                fullURL += "?"
            } else {
                fullURL += "&"
            }
            
            fullURL += "\(key)=\(value)"
            index += 1
        }
        
        return fullURL
    }
}

// MARK: - Log
private extension ArminClient {
    func log(info: String,
             extra: String? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.logTube?.log(info: info,
                              extra: extra)
        }
    }
    
    func log(warning: String,
             extra: String? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.logTube?.log(warning: warning,
                              extra: extra)
        }
    }
    
    func log(error: Error,
             extra: String? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.logTube?.log(error: error,
                              extra: extra)
        }
    }
}

fileprivate class ArAfterWorker {
    private var pendingRequestWorkItem: DispatchWorkItem?
    
    func perform(after: TimeInterval,
                 on queue: DispatchQueue,
                 _ block: @escaping (() -> Void)) {
        // Cancel the currently pending item
        pendingRequestWorkItem?.cancel()
        
        // Wrap our request in a work item
        let requestWorkItem = DispatchWorkItem(block: block)
        pendingRequestWorkItem = requestWorkItem
        queue.asyncAfter(deadline: .now() + after,
                         execute: requestWorkItem)
    }
    
    func cancel() {
        pendingRequestWorkItem?.cancel()
    }
}

fileprivate class ArRetryHelper {
    private let work = ArAfterWorker()
    
    var maxCount: Int
    var retryCount: Int
    var queue: DispatchQueue
    
    init(maxCount: Int,
         queue: DispatchQueue) {
        self.maxCount = maxCount
        self.retryCount = 0
        self.queue = queue
    }
    
    func ifNeedRetry() -> Bool {
        if retryCount >= maxCount {
            return false
        } else {
            return true
        }
    }
    
    func perform(_ block: @escaping (() -> Void)) {
        retryCount += 1
        
        guard ifNeedRetry() else {
            return
        }
        
        let after = (TimeInterval(retryCount) * 0.25)
        
        work.perform(after: after,
                     on: queue,
                     block)
    }
}

fileprivate extension NSError {
    convenience init(code: Int,
                     message: String) {
        self.init(domain: "Armin",
                  code: code,
                  userInfo: ["message": message])
    }
}

fileprivate extension Data {
    func json() throws -> [String: Any] {
        let object = try JSONSerialization.jsonObject(with: self,
                                                      options: [])
        
        guard let json = object as? [String: Any] else {
            throw NSError(code: -1,
                          message: "data is convert to json unsuccessfully")
        }
        
        return json
    }
}

fileprivate extension ArHttpMethod {
    var alType: HTTPMethod {
        switch self {
        case .options: return .options
        case .get:     return .get
        case .head:    return .head
        case .post:    return .post
        case .put:     return .put
        case .patch:   return .patch
        case .delete:  return .delete
        case .trace:   return .trace
        case .connect: return .connect
        }
    }
}

fileprivate extension HTTPMethod {
     var encoding: ParameterEncoding {
        switch self {
        case .get:   return URLEncoding.default
        case .post:  return JSONEncoding.default
        default:     return JSONEncoding.default
        }
    }
}
