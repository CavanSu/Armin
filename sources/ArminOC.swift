//
//  Armin_OC.swift
//  Armin
//
//  Created by CavanSu on 2020/8/18.
//  Copyright © 2020 CavanSu. All rights reserved.
//

@objc public protocol ArminDelegateOC: NSObjectProtocol {
    func armin(_ client: ArminOC,
               requestSuccess event: ArRequestEventOC,
               startTime: TimeInterval,
               url: String)
    func armin(_ client: ArminOC,
               requestFail error: ArErrorOC,
               event: ArRequestEventOC,
               url: String)
}

@objc public class ArErrorOC: NSError {
    
}

@objc public class ArminOC: Armin {
    @objc public weak var delegateOC: ArminDelegateOC?
    @objc public weak var logTubeOC: ArLogTubeOC?
    
    @objc public init(delegate: ArminDelegateOC? = nil,
                      logTube: ArLogTubeOC? = nil) {
        self.delegateOC = delegate
        super.init(delegate: nil,
                   logTube: nil)
        self.logTube = self
        self.delegate = self
        self.logTubeOC = logTube
    }
    
    @objc public func request(task: ArRequestTaskOC,
                              responseOnMainQueue: Bool = true,
                              successCallbackContent: ArResponseTypeOC,
                              success: ((ArResponseOC) -> Void)? = nil,
                              fail: ArErrorRetryCompletionOC = nil) {
        let swift_task = ArRequestTask.oc(task)
        
        var response: ArResponse
        
        switch successCallbackContent {
        case .json:
            response = ArResponse.json({ (json) in
                let response_oc = ArResponseOC(type: successCallbackContent,
                                               json: json,
                                               data: nil)
                
                if let success = success {
                    success(response_oc)
                }
            })
        case .data:
            response = ArResponse.data({ (data) in
                let response_oc = ArResponseOC(type: successCallbackContent,
                                               json: nil,
                                               data: data)
                
                if let success = success {
                    success(response_oc)
                }
            })
        case .blank:
            response = ArResponse.blank({
                let response_oc = ArResponseOC(type: successCallbackContent,
                                               json: nil,
                                               data: nil)
                
                if let success = success {
                    success(response_oc)
                }
            })
        }
        
        request(task: swift_task,
                responseOnMainQueue: responseOnMainQueue,
                success: response) { (error) -> ArRetryOptions in
            if let fail = fail {
                let swift_error = error as! ArError
                let oc_error = ArErrorOC(domain: swift_error.localizedDescription,
                                         code: -1,
                                         userInfo: nil)
                let failRetryInterval = fail(oc_error);
                
                if failRetryInterval > 0 {
                    return .retry(after: failRetryInterval)
                } else {
                    return .resign
                }
            } else {
                return .resign
            }
        }
    }
    
    @objc public func upload(task: ArUploadTaskOC,
                             responseOnMainQueue: Bool = true,
                             successCallbackContent: ArResponseTypeOC,
                             success: ((ArResponseOC) -> Void)? = nil,
                             fail: ArErrorRetryCompletionOC = nil) {
        var response: ArResponse
        
        switch successCallbackContent {
        case .json:
            response = ArResponse.json({ (json) in
                let response_oc = ArResponseOC(type: successCallbackContent,
                                               json: json,
                                               data: nil)
                
                if let success = success {
                    success(response_oc)
                }
            })
        case .data:
            response = ArResponse.data({ (data) in
                let response_oc = ArResponseOC(type: successCallbackContent,
                                               json: nil,
                                               data: data)
                
                if let success = success {
                    success(response_oc)
                }
            })
        case .blank:
            response = ArResponse.blank({
                let response_oc = ArResponseOC(type: successCallbackContent,
                                               json: nil,
                                               data: nil)
                
                if let success = success {
                    success(response_oc)
                }
            })
        }
        
        let swift_task = ArUploadTask.oc(task)
        
        upload(task: swift_task,
               responseOnMainQueue: responseOnMainQueue,
               success: response) { (error) -> ArRetryOptions in
            if let fail = fail {
                let swift_error = error as! ArError
                let oc_error = ArErrorOC(domain: swift_error.localizedDescription,
                                         code: -1,
                                         userInfo: nil)
                let failRetryInterval = fail(oc_error);
                
                if failRetryInterval > 0 {
                    return .retry(after: failRetryInterval)
                } else {
                    return .resign
                }
            } else {
                return .resign
            }
        }
    }
}

extension ArminOC: ArminDelegate {
    public func armin(_ client: Armin,
                      requestSuccess event: ArRequestEvent,
                      startTime: TimeInterval,
                      url: String) {
        let eventOC = ArRequestEventOC(name: event.name)
        self.delegateOC?.armin(self,
                               requestSuccess: eventOC,
                               startTime: startTime,
                               url: url)
    }
    
    public func armin(_ client: Armin,
                      requestFail error: ArError,
                      event: ArRequestEvent,
                      url: String) {
        let eventOC = ArRequestEventOC(name: event.name)
        let errorOC = ArErrorOC(domain: error.localizedDescription + (error.extra ?? ""),
                                code: (error.code ?? 0),
                                userInfo: nil)
        self.delegateOC?.armin(self,
                               requestFail: errorOC,
                               event: eventOC,
                               url: url)
    }
}

extension ArminOC: ArLogTube {
    public func log(info: String, extra: String?) {
        logTubeOC?.log(info: info, extra: extra)
    }
    
    public func log(warning: String, extra: String?) {
        logTubeOC?.log(warning: warning, extra: extra)
    }
    
    public func log(error: Error, extra: String?) {
        if let arError = error as? ArError {
            let oc_error = ArErrorOC(domain: arError.localizedDescription,
                                     code: arError.code ?? -1,
                                     userInfo: nil)
            logTubeOC?.log(error: oc_error, extra: extra)
        } else {
            let oc_error = ArErrorOC(domain: error.localizedDescription,
                                     code: -1,
                                     userInfo: nil)
            logTubeOC?.log(error: oc_error, extra: extra)
        }
    }
}

fileprivate extension ArRequestTask {
    static func oc(_ item: ArRequestTaskOC) -> ArRequestTask {
        let swift_event = ArRequestEvent(name: item.event.name)
        let swift_type = ArRequestType.oc(item.requestType)
        
        return ArRequestTask(event: swift_event,
                             type: swift_type,
                             timeout: .custom(item.timeout),
                             header: item.header,
                             parameters: item.parameters)
    }
}

fileprivate extension ArRequestType {
    static func oc(_ item: ArRequestTypeObjectOC) -> ArRequestType {
        switch item.type {
        case .http:
            if let http = item as? ArRequestTypeJsonObjectOC {
                return ArRequestType.http(ArHttpMethod.oc(http.method),
                                          url: http.url)
            } else {
                fatalError("ArRequestType error")
            }
        case .socket:
            if let socket = item as? ArRequestTypeSocketObjectOC {
                return ArRequestType.socket(peer: socket.peer)
            } else {
                fatalError("ArRequestType error")
            }
        }
    }
}

fileprivate extension ArHttpMethod {
    static func oc(_ item: ArHTTPMethodOC) -> ArHttpMethod {
        switch item {
        case .options: return .options
        case .connect: return .connect
        case .delete:  return .delete
        case .get:     return .get
        case .head:    return .head
        case .patch:   return .patch
        case .post:    return .post
        case .put:     return .put
        case .trace:   return .trace
        }
    }
}

fileprivate extension ArFileMIME {
    static func oc(_ item: ArFileMIMEOC) -> ArFileMIME {
        switch item {
        case .png: return .png
        case .zip: return .zip
        }
    }
}

fileprivate extension ArUploadTask {
    static func oc(_ item: ArUploadTaskOC) -> ArUploadTask {
        let siwft_mime = ArFileMIME.oc(item.object.mime)
        let swift_object = ArUploadObject(fileKeyOnServer: item.object.fileKeyOnServer,
                                          fileName: item.object.fileName,
                                          fileData: item.object.fileData,
                                          mime: siwft_mime)
        
        let swift_event = ArRequestEvent(name: item.event.name)
        
        let swift_task = ArUploadTask(event: swift_event,
                                      timeout: .custom(item.timeout),
                                      object: swift_object,
                                      url: item.url,
                                      header: item.header,
                                      parameters: item.header)
        return swift_task
    }
}
