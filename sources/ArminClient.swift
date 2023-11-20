//
//  ArminClient.swift
//  Pods
//
//  Created by Cavan on 2023/10/30.
//

import Foundation

enum ArHeaderContentType {
    case json, octetStream(fileURL: URL)
}

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
        let sessionId = openSession(event: event,
                                    timeout: timeout.value,
                                    retryCount: retryCount)
        
        startRequest(sessionId: sessionId,
                     headerContentType: .json,
                     url: url,
                     headers: headers,
                     parameters: parameters,
                     method: method,
                     responseQueue: responseQueue,
                     event: event,
                     success: success,
                     failure: failure)
    }
    
    @objc public func objc_upload(fileURL: URL,
                                  to url: String,
                                  headers: [String: String]?,
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
        
        upload(fileURL: fileURL,
               to: url,
               method: method,
               event: event,
               timeout: .custom(timeout),
               responseQueue: responseQueue,
               retryCount: retryCount,
               success: closure,
               failure: failure)
    }
    
    @objc public func objc_upload(fileURL: URL,
                                  to url: String,
                                  headers: [String: String]?,
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
        
        upload(fileURL: fileURL,
               to: url,
               method: method,
               event: event,
               timeout: .custom(timeout),
               responseQueue: responseQueue,
               retryCount: retryCount,
               success: closure,
               failure: failure)
    }
    
    @objc public func objc_upload(fileURL: URL,
                                  to url: String,
                                  headers: [String: String]?,
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
        
        upload(fileURL: fileURL,
               to: url,
               method: method,
               event: event,
               timeout: .custom(timeout),
               responseQueue: responseQueue,
               retryCount: retryCount,
               success: closure,
               failure: failure)
    }
    
    public func upload(fileURL: URL,
                       to url: String,
                       headers: [String: String]? = nil,
                       method: ArHttpMethod,
                       event: String,
                       timeout: ArRequestTimeout = .medium,
                       responseQueue: DispatchQueue = .main,
                       retryCount: Int = 0,
                       success: ArSuccessCompletion? = nil,
                       failure: ArErrorCompletion? = nil) {
        let sessionId = openSession(event: event,
                                    timeout: timeout.value,
                                    retryCount: retryCount)
        
        startRequest(sessionId: sessionId,
                     headerContentType: .octetStream(fileURL: fileURL),
                     url: url,
                     headers: headers,
                     method: method,
                     responseQueue: responseQueue,
                     event: event,
                     success: success,
                     failure: failure)
    }
}

// MARK: - Step 1: Open session & Step 5: Close session
extension ArminClient {
    func openSession(event: String,
                     timeout: TimeInterval,
                     retryCount: Int) -> String {
        taskId += 1
        
        let sessionId = "\(event)-\(taskId)"
        
        let _ = addSession(timeout: timeout,
                           id: sessionId)
        
        let _ = addRetryHelper(id: sessionId,
                               count: retryCount)
        
        return sessionId
    }
    
    func closeSession(_ id: String) {
        removeSession(id: id)
        removeRetryHelper(id: id)
    }
}

// MARK: - Step 2: Request
extension ArminClient {
    func startRequest(sessionId: String,
                      headerContentType: ArHeaderContentType,
                      url: String,
                      headers: [String: String]?,
                      parameters: [String: Any]? = nil,
                      method: ArHttpMethod,
                      responseQueue: DispatchQueue,
                      event: String,
                      success: ArSuccessCompletion?,
                      failure: ArErrorCompletion?) {
        var extra = "url: \(url)"
        extra += ", headers: \(optionalDescription(headers))"
        extra += ", parameters: \(optionalDescription(parameters))"
        
        log(info: "http request, event: \(event)",
            extra: extra)
        
        do {
            let session = try getSession(id: sessionId)
            let retryHelper = try getRetryHelper(id: sessionId)
            
            let request = createRequest(session: session,
                                        headerContentType: headerContentType,
                                        method: method,
                                        url: url,
                                        headers: headers,
                                        parameters: parameters)
            
            handleResponse(request: request,
                           url: url,
                           event: event,
                           queue: responseQueue,
                           success: success) { [weak self] in
                self?.closeSession(sessionId)
            } ifRetry: { [weak self, weak retryHelper] (error) in
                // MARK: - Step 4: Retry
                
                if let `retryHelper` = retryHelper,
                   retryHelper.ifNeedRetry() {
                    
                    let count = retryHelper.retryCount + 1
                    let max = retryHelper.maxCount
                    
                    retryHelper.perform { [weak self] in
                        self?.log(info: "http request retry: \(count), max: \(max), event: \(event)",
                                  extra: extra)
                        
                        self?.startRequest(sessionId: sessionId,
                                           headerContentType: headerContentType,
                                           url: url,
                                           headers: headers,
                                           parameters: parameters,
                                           method: method,
                                           responseQueue: responseQueue,
                                           event: event,
                                           success: success,
                                           failure: failure)
                    }
                } else {
                    failure?(error)
                    self?.closeSession(sessionId)
                }
            }
        } catch {
            failure?(error)
        }
    }
    
    func createRequest(session: SessionManager,
                       headerContentType: ArHeaderContentType,
                       method: ArHttpMethod,
                       url: String,
                       headers: [String: String]?,
                       parameters: [String: Any]?) -> DataRequest {
        var dataRequest: DataRequest
        
        switch headerContentType {
        case .json:
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
        case .octetStream(let fileURL):
            dataRequest = session.upload(fileURL,
                                         to: url,
                                         method: method.alType,
                                         headers: headers)
        }
        
        return dataRequest
    }
}

// MARK: - Step 3: Response
extension ArminClient {
    func handleResponse(request: DataRequest,
                        url: String,
                        event: String,
                        queue: DispatchQueue,
                        success: ArSuccessCompletion? = nil,
                        completion: @escaping ArCompletion,
                        ifRetry: @escaping ArErrorCompletion) {
        request.responseData(queue: queue) { [weak self] (dataResponse) in
            guard let strongSelf = self else {
                return
            }
            
            do {
                let data = try strongSelf.checkResponse(dataResponse)
                
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
                
                strongSelf.log(info: info,
                               extra: extra)
                
                completion()
            } catch let error {
                var extra = "http request unsunccessfully, event: \(event)"
                extra += ", url: \(url)"
                
                strongSelf.log(error: error,
                               extra: extra)
                
                ifRetry(error)
            }
        }
    }
    
    func checkResponse(_ response: DataResponse<Data>) throws -> Data {
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
    
    func getSession(id: String) throws -> SessionManager {
        guard let session = sessions[id] else {
            throw NSError(code: -1,
                          message: "get session nil")
        }
        
        return session
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
    
    func getRetryHelper(id: String) throws -> ArRetryHelper {
        guard let retryHelper = retryHelpers[id] else {
            throw NSError(code: -1,
                          message: "get session nil")
        }
        
        return retryHelper
    }
    
    func removeRetryHelper(id: String) {
        retryHelpers.removeValue(forKey: id)
    }
}

private extension ArminClient {
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
    
    func optionalDescription<T>(_ any: T?) -> String where T : CustomStringConvertible {
        if let `any` = any {
            return any.description
        } else {
            return "nil"
        }
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
