//
//  Armin.swift
//  Armin
//
//  Created by CavanSu on 2019/6/23.
//  Copyright © 2019 CavanSu. All rights reserved.
//

/**
Armin owns only one URLSessionManager and one ArSessionDelegate which is weak and implements URLSession, because the session will strong own its URLSessionManager.
 */

import Foundation

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

open class Armin: NSObject, ArRequestAPIsProtocol {
    public weak var delegate: ArminDelegate?
    public weak var logTube: ArLogTube?
    
    private let session: URLSession
    private let fileHandler = ArFileHandler()
    private let requestMaker = ArRequestMaker()
    
    // String: ArRequestEvent name
    private lazy var afterWorkers = [String: AfterWorker]()
    
    // Key为URLSessionTask的taskIdentifier，以便于在URLSessionDelegate中取值，目前只处理download tasks
    private(set) lazy var taskHandlers = [Int: ArTaskHandler]()
    
    private var responseQueue = DispatchQueue(label: "com.armin.response.thread")
    private var afterQueue = DispatchQueue(label: "com.armin.after.thread")
    
    public init(delegate: ArminDelegate? = nil,
                logTube: ArLogTube? = nil) {
        self.delegate = delegate
        self.logTube = logTube
        
        let sessionDelegate = ArSessionDelegator()
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.httpAdditionalHeaders = Armin.defaultHTTPHeaders
        self.session = URLSession(configuration: URLSessionConfiguration.default,
                                  delegate: sessionDelegate,
                                  delegateQueue: .current)
        
        super.init()
        sessionDelegate.setArmin(self)
        sessionDelegate.setFileHandler(self.fileHandler)
    }
    
    func handleHttpSuccess(data: Data?,
                           location: String? = nil,
                           startTime: TimeInterval,
                           from task: ArRequestTaskProtocol,
                           success: ArResponse?) {
        
        requestSuccess(of: task.event,
                       startTime: startTime,
                       with: task.requestType.url!)
        
        guard let successRes = success else {
            return
        }
        
        switch successRes {
        case .json(let arDicEXCompletion):
            guard let _data = data,
                  let json = try? _data.json() else {
                      break
            }
            
            self.log(info: "request success",
                     extra: "event: \(task.event), json: \(json.description)")
            guard let completion = arDicEXCompletion else {
                break
            }
            
            try? completion(json)
        case .data(let arDataExCompletion):
            guard let _data = data else {
                break
            }
            self.log(info: "request success",
                     extra: "event: \(task.event), data.count: \(_data.count)")
            guard let completion = arDataExCompletion else {
                break
            }
            
            try? completion(_data)
        case .string(let arStringCompletion):
            guard let filePath = location else {
                break
            }
            self.log(info: "request success",
                     extra: "event: \(task.event),path: \(filePath)")
            guard let completion = arStringCompletion else {
                break
            }
            try? completion(filePath)
        case .blank(let arCompletion):
            self.log(info: "request success",
                     extra: "event: \(task.event)")
            guard let completion = arCompletion else {
                break
            }
            completion()
        }
    }
}

// MARK: - ArRequestAPIsProtocol
public extension Armin {
    func request(task: ArRequestTaskProtocol,
                 responseOnQueue: DispatchQueue? = nil,
                 success: ArResponse? = nil,
                 failRetry: ArErrorRetryCompletion = nil) {
        let queue = responseOnQueue == nil ? self.responseQueue : responseOnQueue
        executeRequst(task: task,
                      responseOnQueue: queue!,
                      success: success) { [weak self] (error) in
            guard let `self` = self else {
                return
            }
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
                responseOnQueue: DispatchQueue? = nil,
                success: ArResponse? = nil,
                failRetry: ArErrorRetryCompletion = nil) {
        let queue = responseOnQueue == nil ? self.responseQueue : responseOnQueue
        executeUpload(task: task,
                      responseOnQueue: queue!,
                      success: success) { [weak self] (error) in
            guard let `self` = self else {
                return
            }
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
    
    func download(task: ArDownloadTaskProtocol,
                  responseOnQueue: DispatchQueue? = nil,
                  progress: ArDownloadProgress = nil,
                  success: ArResponse?,
                  failRetry: ArErrorRetryCompletion) {
        let queue = responseOnQueue == nil ? self.responseQueue : responseOnQueue
        executeDownload(task: task,
                        responseOnQueue: queue!,
                        progress: progress,
                        success: success) { [weak self] (error) in
            guard let `self` = self else {
                return
            }
            
            guard let eRetry = failRetry else {
                self.removeWorker(of: task.event)
                return
            }
            let option = eRetry(error)
            switch option {
            case .retry(let time, let newTask):
                var reTask: ArDownloadTaskProtocol
                if let newReTask = newTask as? ArDownloadTaskProtocol {
                    reTask = newReTask
                } else {
                    reTask = task
                }
                
                let work = self.worker(of: reTask.event)
                work.perform(after: time, on: self.afterQueue, {
                    self.download(task: reTask,
                                  responseOnQueue: responseOnQueue,
                                  progress: progress,
                                  success: success,
                                  failRetry: failRetry)
                })
            case .resign:
                break
            }
        }
    }
    
    func stopTasks(urls: [String]?) {
        guard let allUrls = urls else {
            taskHandlers.keys.forEach {[weak self] id in
                self?.removeTask(taskId: id)
            }
            return
        }
        
        for url in allUrls {
            for (id,handler) in taskHandlers {
                if handler.urlStr == url {
                    removeTask(taskId: id)
                }
            }
        }
    }
    
    func removeTask(taskId: Int) {
        taskHandlers[taskId]?.sessionTask.cancel()
        taskHandlers.removeValue(forKey: taskId)
    }
}

// MARK: private
private extension Armin {
    func executeRequst(task: ArRequestTaskProtocol,
                       responseOnQueue: DispatchQueue,
                       success: ArResponse?,
                       requestFail: ArErrorCompletion) {
        guard let method = task.requestType.httpMethod else {
            requestFail?(ArError(type: .valueNil("method")))
            return
        }
        
        guard let urlStr = task.requestType.url else {
            requestFail?(ArError(type: .valueNil("url")))
            return
        }
        
        var request: URLRequest?
        do {
            request = try requestMaker.makeRequest(urlstr: urlStr,
                                                   timeout: task.timeout.value,
                                                   method: method,
                                                   headers: task.header,
                                                   params: task.parameters)
        }catch{
            requestFail?(error as! ArError)
            return
        }
        
        guard let `request` = request else {
            requestFail?(ArError(type: .valueNil("request")))
            return
        }

        let startTime = Date.timeIntervalSinceReferenceDate
        let dataTask = session.dataTask(with: request) {[weak self] (data, response, error) in
            guard let `self` = self else {
                return
            }

            // handle error
            if let err = error {
                let arError = ArError.fail(err.localizedDescription,
                                           code: -1,
                                           extra: nil,
                                           responseData: data)
                self.request(error: arError,
                             of: task.event,
                             with: urlStr)
                requestFail?(arError)
                return
            }
            
            // handle success
            self.handleHttpSuccess(data: data,
                                    startTime: startTime,
                                    from: task,
                                    success: success)
        }

        dataTask.resume()
    }
    
    func executeUpload(task: ArUploadTaskProtocol,
                       responseOnQueue: DispatchQueue,
                       success: ArResponse?,
                       requestFail: ArErrorCompletion) {
        let method = ArHttpMethod.post
        guard let urlStr = task.requestType.url,
              let url = requestMaker.makeUrl(urlstr: urlStr,
                                             httpMethod: method,
                                             parameters: task.parameters) else {
                  requestFail?(ArError(type: .valueNil("url")))
                  return
        }
        
        let startTime = Date.timeIntervalSinceReferenceDate

        let multiRequest = MultipartFormDataRequest(method: method,
                                                    url: url,
                                                    timeout: task.timeout)
        
        multiRequest.addDataField(named: task.object.fileName,
                                  data: task.object.fileData,
                                  mimeType: task.object.mime.text)
        let uploadTask = session.dataTask(with: multiRequest.toURLRequest()) {[weak self] (data, response, error) in
            guard let `self` = self else {
                return
            }

            // handle error
            if let err = error {
                let arError = ArError.fail(err.localizedDescription,
                                           code: -1,
                                           extra: nil,
                                           responseData: data)
                self.request(error: arError,
                             of: task.event,
                             with: urlStr)
                requestFail?(arError)
                return
            }
            
            // handle success
            responseOnQueue.async {
                self.handleHttpSuccess(data: data,
                                       startTime: startTime,
                                       from: task,
                                       success: success)
            }
            
        }

        uploadTask.resume()
    }
    
    func executeDownload(task: ArDownloadTaskProtocol,
                         responseOnQueue: DispatchQueue,
                         progress: ArDownloadProgress = nil,
                         success: ArResponse?,
                         requestFail: ArErrorCompletion) {
        let method = ArHttpMethod.download
        guard let urlStr = task.requestType.url,
              let url = requestMaker.makeUrl(urlstr: urlStr,
                                             httpMethod: method,
                                             parameters: task.parameters) else {
                  let arError = ArError(type: .valueNil("url"))
                  requestFail?(arError)
                  return
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.stringValue
        
        let startTime = Date.timeIntervalSinceReferenceDate
        
        let downloadTask = session.downloadTask(with: url)
        do {
            try addTaskHandler(task: task,
                               sessionTask: downloadTask,
                               urlStr: urlStr,
                               responseQueue: responseOnQueue,
                               startTime: startTime,
                               progress: progress,
                               success: success,
                               requestFail: requestFail)
        } catch {
            self.request(error: error as! ArError,
                         of: task.event,
                         with: urlStr)
            requestFail?(error as! ArError)
            return
        }

        downloadTask.resume()
    }
    
    func addTaskHandler(task: ArRequestTaskProtocol,
                        sessionTask: URLSessionTask,
                        urlStr: String,
                        responseQueue: DispatchQueue,
                        startTime: TimeInterval,
                        progress: ArDownloadProgress,
                        success: ArResponse?,
                        requestFail: ArErrorCompletion) throws {
        guard !taskHandlers.keys.contains(task.id) else {
            throw ArError(type: .taskExists(task.id))
        }
        taskHandlers[sessionTask.taskIdentifier] = ArTaskHandler(task: task,
                                                                 sessionTask: sessionTask,
                                                                 urlStr: urlStr,
                                                                 responseQueue: responseQueue,
                                                                 startTime: startTime,
                                                                 progress: progress,
                                                                 success: success,
                                                                 requestFail: requestFail)
    }
    
    func removeTask(url: String) {
        for handler in taskHandlers.enumerated() {
            if handler.element.value.urlStr == url {
                taskHandlers.removeValue(forKey: handler.element.key)
            }
        }
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
    
    func handleHttpError(error: Error?,
                         data: Data?,
                         requestUrl: String,
                         event: ArRequestEvent,
                         requestFail: ArErrorCompletion) -> ArError? {
        if let err = error {
            let arError = ArError.fail(err.localizedDescription,
                                       code: -1,
                                       extra: nil,
                                       responseData: data)
            self.request(error: arError,
                         of: event,
                         with: requestUrl)
            requestFail?(arError)
            return arError
        }
//        else if let _data = data,
//           let arError = _data.toArError() {
//            self.request(error: arError,
//                         of: event,
//                         with: requestUrl)
//            requestFail?(arError)
//            return arError
//        }
        return nil
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
