//
//  Armin_OC.swift
//  Pods
//
//  Created by CavanSu on 2020/8/18.
//

@objc public class ArminOC: Armin {
    @objc public init() {
        super.init(delegate: nil, logTube: nil)
    }
    
    @objc public func request(task: ArRequestTaskOC,
                              responseOnMainQueue: Bool = true,
                              successCallbackContent: ArResponseTypeOC,
                              success: ((ArResponseOC) -> Void)? = nil,
                              failRetryInterval: TimeInterval = -1,
                              fail: ArErrorCompletion = nil) {
        
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
                    if failRetryInterval > 0 {
                        return .retry(after: failRetryInterval)
                    } else {
                        return .resign
                    }
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
                return ArRequestType.http(ArHttpMethod.oc(http.method), url: http.url)
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
