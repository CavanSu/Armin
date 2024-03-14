//
//  ArminClient.swift
//  Pods
//
//  Created by Cavan on 2023/10/30.
//

import Foundation

@objc public protocol ArminClientDelegate: NSObjectProtocol {
    func onRequestedFailure(error: Error)
}

enum ArHeaderContentType {
    case json, octetStream(fileURL: URL)
}

@objc open class ArminClient: NSObject {
    private lazy var sessions = [String: SessionManager]()    // Key: sessionId
    private lazy var retrys = [String: ArRetry]()             // Key: sessionId
    
    private var taskId = 0
    
    private var afterQueue = DispatchQueue(label: "com.armin.retry.thread")
    
    @objc public let localErrorCode = -1
    
    public weak var logTube: ArLogTube?
    
    public weak var delegate: ArminClientDelegate?
    
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
                                   failure: ArErrorCompletion?,
                                   cancelRetry: ArErrorRetryCompletion?) {
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
                                   failure: ArErrorCompletion?,
                                   cancelRetry: ArErrorRetryCompletion?) {
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
                                   failure: ArErrorCompletion?,
                                   cancelRetry: ArErrorRetryCompletion?) {
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
                        failure: ArErrorCompletion? = nil,
                        cancelRetry: ArErrorRetryCompletion? = nil) {
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
                     failure: failure,
                     cancelRetry: cancelRetry)
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
                                  failure: ArErrorCompletion?,
                                  cancelRetry: ArErrorRetryCompletion?) {
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
               failure: failure,
               cancelRetry: cancelRetry)
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
                                  failure: ArErrorCompletion?,
                                  cancelRetry: ArErrorRetryCompletion?) {
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
               failure: failure,
               cancelRetry: cancelRetry)
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
                                  failure: ArErrorCompletion?,
                                  cancelRetry: ArErrorRetryCompletion?) {
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
               failure: failure,
               cancelRetry: cancelRetry)
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
                       failure: ArErrorCompletion? = nil,
                       cancelRetry: ArErrorRetryCompletion? = nil) {
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
                     failure: failure,
                     cancelRetry: cancelRetry)
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
        
        let _ = addRetry(id: sessionId,
                         count: retryCount)
        
        return sessionId
    }
    
    func closeSession(_ id: String) {
        removeSession(id: id)
        removeRetry(id: id)
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
                      failure: ArErrorCompletion?,
                      cancelRetry: ArErrorRetryCompletion?) {
        let extra = ["url": url,
                     "headers": optionalDescription(headers),
                     "parameters": optionalDescription(parameters)]
        
        log(info: "http request, event: \(event)",
            extra: extra)
        
        do {
            let session = try getSession(id: sessionId)
            let retry = try getRetry(id: sessionId)
            
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
            } ifRetry: { [weak self, weak retry] (error) in
                // MARK: - Step 4: Retry
                
                guard let `retry` = retry else {
                    failure?(error)
                    self?.delegate?.onRequestedFailure(error: error)
                    self?.closeSession(sessionId)
                    return
                }
                
                let internalNeedRetry = retry.ifNeedRetry()
                var externalNeedRetry: Bool = true
                
                if let `cancelRetry` = cancelRetry {
                    externalNeedRetry = cancelRetry(error)
                }
                
                guard internalNeedRetry,
                      externalNeedRetry else {
                    failure?(error)
                    self?.delegate?.onRequestedFailure(error: error)
                    self?.closeSession(sessionId)
                    return
                }
                
                let count = retry.retryCount + 1
                let max = retry.maxCount
                
                retry.perform { [weak self] in
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
                                       failure: failure,
                                       cancelRetry: cancelRetry)
                }
            }
        } catch {
            failure?(error)
            delegate?.onRequestedFailure(error: error)
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
                
                let info = "http request successfully"
                
                var extra = ["url": url,
                             "event": event]
                
                if let `success` = success {
                    switch success {
                    case .json(let closure):
                        let json = try data.json(localErrorCode: strongSelf.localErrorCode)
                        
                        extra["response json"] = json.description
                        
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
                let extra = ["error": "http request unsuccessfully",
                             "event": event,
                             "url": url]
                
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
            throw ArError(code: localErrorCode,
                          message: "http code nil")
        }
        
        guard statusCode == 200 else {
            throw ArError(code: statusCode,
                          message: "http code error",
                          data: response.data)
        }
        
        guard let data = response.data else {
            throw ArError(code: localErrorCode,
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
            throw ArError(code: localErrorCode,
                          message: "get session nil")
        }
        
        return session
    }
    
    func removeSession(id: String) {
        sessions.removeValue(forKey: id)
    }
    
    func addRetry(id: String,
                  count: Int) -> ArRetry {
        let helper = ArRetry(maxCount: count,
                             queue: afterQueue)
        
        retrys[id] = helper
        
        return helper
    }
    
    func getRetry(id: String) throws -> ArRetry {
        guard let Retry = retrys[id] else {
            throw ArError(code: localErrorCode,
                          message: "get retry nil")
        }
        
        return Retry
    }
    
    func removeRetry(id: String) {
        retrys.removeValue(forKey: id)
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
             extra: [String: Any]? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.logTube?.onLog(info: info,
                                extra: extra)
        }
    }
    
    func log(warning: String,
             extra: [String: Any]? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.logTube?.onLog(warning: warning,
                                extra: extra)
        }
    }
    
    func log(error: Error,
             extra: [String: Any]? = nil) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.logTube?.onLog(error: error,
                                extra: extra)
        }
    }
}

fileprivate extension ArError {
    convenience init(code: Int,
                     message: String,
                     data: Data? = nil) {
        let userInfo: [String: Any] = ["message": message]
        
        self.init(domain: "Armin",
                  code: code,
                  userInfo: userInfo)
        
        self.data = data
    }
}

fileprivate extension Data {
    func json(localErrorCode: Int) throws -> [String: Any] {
        let object = try JSONSerialization.jsonObject(with: self,
                                                      options: [])
        
        guard let json = object as? [String: Any] else {
            throw ArError(code: localErrorCode,
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
