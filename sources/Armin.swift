//
//  Armin.swift
//  Armin
//
//  Created by CavanSu on 2019/6/23.
//  Copyright © 2019 CavanSu. All rights reserved.
//

import Alamofire

public protocol ArminDelegate: NSObjectProtocol {
    func armin(_ client: Armin,
               requestSuccess event: ArRequestEvent,
               startTime: TimeInterval,
               url: String)
    func armin(_ client: Armin,
               requestFail error: ArError,
               event: ArRequestEvent,
               url: String)
}

public class Armin: NSObject, ArRequestAPIsProtocol {
    private lazy var instances = [Int: SessionManager]() // Int: taskId
    private lazy var afterWorkers = [String: AfterWorker]() // String: ArRequestEvent name
    
    private var responseQueue = DispatchQueue(label: "com.armin.response.thread")
    private var afterQueue = DispatchQueue(label: "com.armin.after.thread")
    
    public weak var delegate: ArminDelegate?
    public weak var logTube: ArLogTube?
    
    public init(delegate: ArminDelegate? = nil,
                logTube: ArLogTube? = nil) {
        self.delegate = delegate
        self.logTube = logTube
    }
}

public extension Armin {
    @objc func getCookieArray()-> [HTTPCookie]? {
        let cookieStorage = HTTPCookieStorage.shared
        let cookieArray = cookieStorage.cookies
        return cookieArray
    }
    
    @objc func insertCookie(_ cookie: HTTPCookie) {
        HTTPCookieStorage.shared.setCookie(cookie)
    }
}

public extension Armin {
    func request(task: ArRequestTaskProtocol,
                 responseOnMainQueue: Bool = true,
                 success: ArResponse? = nil,
                 failRetry: ArErrorRetryCompletion = nil) {
        privateRequst(task: task,
                      responseOnMainQueue: responseOnMainQueue,
                      success: success) { [unowned self] (error) in
            guard let eRetry = failRetry else {
                self.removeWorker(of: task.event)
                return
            }
            
            let option = eRetry(error)
            switch option {
            case .retry(let time, let newTask):
                var reTask: ArRequestTaskProtocol
                
                if let newTask = newTask {
                    reTask = newTask
                } else {
                    reTask = task
                }
                
                let work = self.worker(of: reTask.event)
                work.perform(after: time,
                             on: self.afterQueue, {
                                self.request(task: reTask,
                                             success: success,
                                             failRetry: failRetry)
                             })
            case .resign:
                break
            }
        }
    }
    
    func upload(task: ArUploadTaskProtocol,
                responseOnMainQueue: Bool = true,
                success: ArResponse? = nil,
                failRetry: ArErrorRetryCompletion = nil) {
        privateUpload(task: task,
                      success: success) { [unowned self] (error) in
            guard let eRetry = failRetry else {
                self.removeWorker(of: task.event)
                return
            }
            
            let option = eRetry(error)
            switch option {
            case .retry(let time, let newTask):
                var reTask: ArUploadTaskProtocol
                
                if let newTask = newTask as? ArUploadTaskProtocol {
                    reTask = newTask
                } else {
                    reTask = task
                }
                
                let work = self.worker(of: reTask.event)
                work.perform(after: time, on: self.afterQueue, {
                    self.upload(task: reTask, success: success, failRetry: failRetry)
                })
            case .resign:
                break
            }
        }
    }
}

// MARK: Request
public typealias ArHttpMethod = HTTPMethod

extension HTTPMethod {
    fileprivate var encoding: ParameterEncoding {
        switch self {
        case .get:   return URLEncoding.default
        case .post:  return JSONEncoding.default
        default:     return JSONEncoding.default
        }
    }
}

private extension Armin {
    func privateRequst(task: ArRequestTaskProtocol,
                       responseOnMainQueue: Bool = true,
                       success: ArResponse?,
                       requestFail: ArErrorCompletion) {
        guard let httpMethod = task.requestType.httpMethod else {
            fatalError("Request Type error")
        }
        
        guard var url = task.requestType.url else {
            fatalError("Request Type error")
        }
        
        let timeout = task.timeout.value
        let taskId = task.id
        let startTime = Date.timeIntervalSinceReferenceDate
        let instance = alamo(timeout,
                             id: taskId)
        
        var dataRequest: DataRequest
        
        if httpMethod == .get {
            if let parameters = task.parameters {
                url = urlAddParameters(url: url,
                                       parameters: parameters)
            }
            dataRequest = instance.request(url,
                                           method: httpMethod,
                                           encoding: httpMethod.encoding,
                                           headers: task.header)
        } else {
            dataRequest = instance.request(url,
                                           method: httpMethod,
                                           parameters: task.parameters,
                                           encoding: httpMethod.encoding,
                                           headers: task.header)
        }
        
        log(info: "http request, event: \(task.event.description)",
            extra: "url: \(url), parameter: \(OptionsDescription.any(task.parameters))")
        
        let queue = responseQueue
        
        dataRequest.responseData(queue: queue) { [weak self] (dataResponse) in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.removeInstance(taskId)
            strongSelf.removeWorker(of: task.event)
            
            if responseOnMainQueue {
                DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self else {
                        return
                    }
                    
                    strongSelf.handle(dataResponse: dataResponse,
                                      from: task,
                                      url: url,
                                      startTime: startTime,
                                      success: success,
                                      fail: requestFail)
                }
            } else {
                strongSelf.handle(dataResponse: dataResponse,
                                  from: task,
                                  url: url,
                                  startTime: startTime,
                                  success: success,
                                  fail: requestFail)
            }
        }
    }
    
    func privateUpload(task: ArUploadTaskProtocol,
                       responseOnMainQueue: Bool = true,
                       success: ArResponse?,
                       requestFail: ArErrorCompletion) {
        guard let _ = task.requestType.httpMethod else {
            fatalError("Request Type error")
        }
        
        guard let url = task.requestType.url else {
            fatalError("Request Type error")
        }
        
        let timeout = task.timeout.value
        let taskId = task.id
        let startTime = Date.timeIntervalSinceReferenceDate
        let instance = alamo(timeout, id: taskId)
        
        log(info: "http upload, event: \(task.event.description)",
            extra: "url: \(url), parameter: \(OptionsDescription.any(task.parameters))")
        
        var queue: DispatchQueue
        if responseOnMainQueue {
            queue = DispatchQueue.main
        } else {
            queue = responseQueue
        }
        
        instance.upload(multipartFormData: { (multiData) in
            multiData.append(task.object.fileData,
                             withName: task.object.fileKeyOnServer,
                             fileName: task.object.fileName,
                             mimeType: task.object.mime.text)
            
            guard let parameters = task.parameters else {
                return
            }
            
            for (key, value) in parameters {
                if let stringValue = value as? String,
                   let part = stringValue.data(using: String.Encoding.utf8) {
                    multiData.append(part, withName: key)
                } else if var intValue = value as? Int {
                    let part = Data(bytes: &intValue, count: MemoryLayout<Int>.size)
                    multiData.append(part, withName: key)
                }
            }
        }, to: url, headers: task.header) { (encodingResult) in
            switch encodingResult {
            case .success(let upload, _, _):
                upload.uploadProgress(queue: DispatchQueue.main,
                                      closure: { (progress) in
                })
                
                upload.responseData(queue: queue) { [unowned self] (dataResponse) in
                    self.removeInstance(taskId)
                    self.removeWorker(of: task.event)
                    
                    if responseOnMainQueue {
                        DispatchQueue.main.async { [unowned self] in
                            self.handle(dataResponse: dataResponse,
                                        from: task,
                                        url: url,
                                        startTime: startTime,
                                        success: success,
                                        fail: requestFail)
                        }
                    } else {
                        self.handle(dataResponse: dataResponse,
                                    from: task,
                                    url: url,
                                    startTime: startTime,
                                    success: success,
                                    fail: requestFail)
                    }
                }
            case .failure(let error):
                self.removeInstance(taskId)
                let mError = ArError.fail(error.localizedDescription)
                self.request(error: mError,
                             of: task.event,
                             with: url)
                
                guard let requestFail = requestFail  else {
                    return
                }
                
                if responseOnMainQueue {
                    DispatchQueue.main.async {
                        requestFail(mError)
                    }
                } else {
                    requestFail(mError)
                }
            }
        }
    }
    
    func handle(dataResponse: DataResponse<Data>,
                from task: ArRequestTaskProtocol,
                url: String,
                startTime: TimeInterval,
                success: ArResponse?,
                fail: ArErrorCompletion) {
        let result = self.checkResponseData(dataResponse,
                                            event: task.event)
        switch result {
        case .pass(let data):
            self.requestSuccess(of: task.event,
                                startTime: startTime,
                                with: url)
            guard let success = success else {
                break
            }
            
            do {
                switch success {
                case .blank(let completion):
                    self.log(info: "request success",
                             extra: "event: \(task.event)")
                    guard let completion = completion else {
                        break
                    }
                    
                    completion()
                case .data(let completion):
                    self.log(info: "request success",
                             extra: "event: \(task.event), data.count: \(data.count)")
                    guard let completion = completion else {
                        break
                    }
                    
                    try completion(data)
                case .json(let completion):
                    let json = try data.json()
                    self.log(info: "request success",
                             extra: "event: \(task.event), json: \(json.description)")
                    guard let completion = completion else {
                        break
                    }
                    
                    try completion(json)
                }
            } catch {
                var tError: ArError
                
                if let arError = error as? ArError {
                    tError = arError
                } else {
                    tError = ArError.fail(error.localizedDescription)
                }
                
                self.log(error: tError,
                         extra: "event: \(task.event)")
                
                guard let fail = fail else {
                    return
                }
                
                fail(tError)
            }
        case .fail(let error):
            self.request(error: error,
                         of: task.event,
                         with: url)
            self.log(error: error,
                     extra: "event: \(task.event), url: \(url)")
            
            guard let fail = fail else {
                return
            }
            
            fail(error)
        }
    }
}

// MARK: Alamo instance
private extension Armin {
    func alamo(_ timeout: TimeInterval,
               id: Int) -> SessionManager {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        configuration.timeoutIntervalForRequest = timeout
        
        let alamo = Alamofire.SessionManager(configuration: configuration)
        instances[id] = alamo
        return alamo
    }
    
    func removeInstance(_ id: Int) {
        instances.removeValue(forKey: id)
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
    
    func worker(of event: ArRequestEvent) -> AfterWorker {
        var work: AfterWorker
        if let tWork = self.afterWorkers[event.name] {
            work = tWork
        } else {
            work = AfterWorker()
        }
        return work
    }
    
    func removeWorker(of event: ArRequestEvent) {
        afterWorkers.removeValue(forKey: event.name)
    }
}

// MARK: Check Response
private extension Armin {
    enum ResponseCode {
        init(rawValue: Int) {
            if rawValue == 200 {
                self = .success
            } else {
                self = .error(code: rawValue)
            }
        }
        
        case success, error(code: Int)
    }
    
    enum CheckResult {
        case pass, fail(ArError)
        
        var rawValue: Int {
            switch self {
            case .pass: return 0
            case .fail: return 1
            }
        }
        
        static func ==(left: CheckResult, right: CheckResult) -> Bool {
            return left.rawValue == right.rawValue
        }
        
        static func !=(left: CheckResult, right: CheckResult) -> Bool {
            return left.rawValue != right.rawValue
        }
    }
    
    enum CheckDataResult {
        case pass(Data), fail(ArError)
    }
    
    func checkResponseData(_ dataResponse: DataResponse<Data>,
                           event: ArRequestEvent) -> CheckDataResult {
        var dataResult: CheckDataResult = .fail(ArError.unknown())
        var result: CheckResult = .fail(ArError.unknown())
        let code = dataResponse.response?.statusCode
        let data = dataResponse.data
        let checkIndexs = 3
        
        for index in 0 ..< checkIndexs {
            switch index {
            case 0:
                result = checkResponseCode(code,
                                           data: data,
                                           event: event)
            case 1:
                result = checkResponseContent(dataResponse.error,
                                              data: data,
                                              event: event)
            case 2:
                if let data = dataResponse.data {
                    dataResult = .pass(data)
                } else {
                    let error = ArError.fail("response data nil",
                                             code: code,
                                             extra: "event: \(event.description)")
                    dataResult = .fail(error)
                }
            default: break
            }
            
            var isBreak = false
            
            switch result {
            case .fail(let error): dataResult = .fail(error); isBreak = true;
            case .pass: break
            }
            
            if isBreak {
                break
            }
        }
        
        return dataResult
    }
    
    func checkResponseCode(_ code: Int?,
                           data: Data?,
                           event: ArRequestEvent) -> CheckResult {
        var result: CheckResult = .pass
        
        if let code = code {
            let mCode = ResponseCode(rawValue: code)
            
            switch mCode {
            case .success:
                result = .pass
            case .error(let code):
                let error = ArError.fail("response code error",
                                         code: code,
                                         extra: "event: \(event.description)",
                                         responseData: data)
                result = .fail(error)
            }
        } else {
            let error = ArError.fail("connect with server error, response code nil",
                                     extra: "event: \(event.description)",
                                     responseData: data)
            result = .fail(error)
        }
        return result
    }
    
    func checkResponseContent(_ error: Error?,
                              data: Data?,
                              event: ArRequestEvent) -> CheckResult {
        var result: CheckResult = .pass
        
        if let error = error as? AFError {
            let mError = ArError.fail(error.localizedDescription,
                                      code: error.responseCode,
                                      extra: "event: \(event.description)",
                                      responseData: data)
            result = .fail(mError)
        } else if let error = error {
            let mError = ArError.fail(error.localizedDescription,
                                      extra: "event: \(event.description)",
                                      responseData: data)
            result = .fail(mError)
        }
        return result
    }
}

// MARK: CallbArk
private extension Armin {
    func requestSuccess(of event: ArRequestEvent,
                        startTime: TimeInterval,
                        with url: String) {
        DispatchQueue.main.async { [unowned self] in
            self.delegate?.armin(self,
                                 requestSuccess: event,
                                 startTime: startTime,
                                 url: url)
        }
    }
    
    func request(error: ArError,
                 of event: ArRequestEvent,
                 with url: String) {
        DispatchQueue.main.async { [unowned self] in
            self.delegate?.armin(self,
                                 requestFail: error,
                                 event: event,
                                 url: url)
        }
    }
}

// MARK: Log
private extension Armin {
    func log(info: String,
             extra: String? = nil) {
        DispatchQueue.main.async { [unowned self] in
            self.logTube?.log(info: info,
                              extra: extra)
        }
    }
    
    func log(warning: String,
             extra: String? = nil) {
        DispatchQueue.main.async { [unowned self] in
            self.logTube?.log(warning: warning,
                              extra: extra)
        }
    }
    
    func log(error: ArError,
             extra: String? = nil) {
        DispatchQueue.main.async { [unowned self] in
            self.logTube?.log(error: error,
                              extra: extra)
        }
    }
}

// MARK: extension
fileprivate extension Data {
    func json() throws -> [String: Any] {
        let object = try JSONSerialization.jsonObject(with: self, options: [])
        guard let dic = object as? [String: Any] else {
            throw ArError.convert("Any", "[String: Any]")
        }
        
        return dic
    }
}
