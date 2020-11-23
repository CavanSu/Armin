//
//  ArModels.swift
//  ArModels
//
//  Created by CavanSu on 2019/7/11.
//  Copyright © 2019 CavanSu. All rights reserved.
//

import Foundation

public typealias ArDicCompletion = (([String: Any]) -> Void)?
public typealias ArAnyCompletion = ((Any?) -> Void)?
public typealias ArStringCompletion = ((String) -> Void)?
public typealias ArIntCompletion = ((Int) -> Void)?
public typealias ArCompletion = (() -> Void)?

public typealias ArDicEXCompletion = (([String: Any]) throws -> Void)?
public typealias ArStringExCompletion = ((String) throws -> Void)?
public typealias ArDataExCompletion = ((Data) throws -> Void)?

public typealias ArErrorCompletion = ((Error) -> Void)?
public typealias ArErrorBoolCompletion = ((Error) -> Bool)?
public typealias ArErrorRetryCompletion = ((Error) -> ArRetryOptions)?

public typealias ArErrorRetryCompletionOC = ((ArErrorOC) -> ArRetryOptionsOC)?

// MARK: enum
public enum ArRetryOptions {
    case retry(after: TimeInterval, newTask: ArRequestTaskProtocol? = nil), resign
}

public enum ArSwitch: Int, CustomStringConvertible {
    case off = 0, on = 1
    
    public var description: String {
        return cusDescription()
    }
    
    var debugDescription: String {
        return cusDescription()
    }
    
    var boolValue: Bool {
        switch self {
        case .on:  return true
        case .off: return false
        }
    }
    
    var intValue: Int {
        switch self {
        case .on:  return 1
        case .off: return 0
        }
    }
    
    func cusDescription() -> String {
        switch self {
        case .on:  return "on"
        case .off: return "off"
        }
    }
}

public enum ArRequestType {
    case http(ArHttpMethod, url: String), socket(peer: String)
    
    var httpMethod: ArHttpMethod? {
        switch self {
        case .http(let method, _):  return method
        default:                    return nil
        }
    }
    
    var url: String? {
        switch self {
        case .http(_, let url):  return url
        default:                 return nil
        }
    }
}

public enum ArResponse {
    case json(ArDicEXCompletion), data(ArDataExCompletion), blank(ArCompletion)
}

public enum ArRequestTimeout {
    case low, medium, high, custom(TimeInterval)
    
    public var value: TimeInterval {
        switch self {
        case .low:               return 20
        case .medium:            return 10
        case .high:              return 3
        case .custom(let value): return value
        }
    }
}

public enum ArFileMIME {
    case png, zip
    
    public var text: String {
        switch self {
        case .png: return "image/png"
        case .zip: return "application/octet-stream"
        }
    }
}

// MARK: struct
public struct ArRequestEvent: ArRequestEventProtocol {
    public var name: String
    
    public var description: String {
        return cusDescription()
    }
    
    public init(name: String) {
        self.name = name
    }
    
    var debugDescription: String {
        return cusDescription()
    }
    
    func cusDescription() -> String {
        return name
    }
}

public struct ArUploadObject: CustomStringConvertible {
    public var fileKeyOnServer: String
    public var fileName: String
    public var fileData: Data
    public var mime: ArFileMIME
    
    public var description: String {
        return cusDescription()
    }
    
    var debugDescription: String {
        return cusDescription()
    }
    
    func cusDescription() -> String {
        return ["fileKeyOnServer": fileKeyOnServer,
                "fileName": fileName,
                "mime": mime.text].description
    }
}

public struct ArRequestTask: ArRequestTaskProtocol {
    public private(set) var id: Int
    public private(set) var requestType: ArRequestType
    
    public var event: ArRequestEvent
    public var timeout: ArRequestTimeout
    public var header: [String : String]?
    public var parameters: [String : Any]?
    
    public init(event: ArRequestEvent,
                type: ArRequestType,
                timeout: ArRequestTimeout = .medium,
                header: [String: String]? = nil,
                parameters: [String: Any]? = nil) {
        TaskId.value += 1
        self.id = TaskId.value
        self.event = event
        self.requestType = type
        self.timeout = timeout
        self.header = header
        self.parameters = parameters
    }
}

public struct ArUploadTask: ArUploadTaskProtocol, CustomStringConvertible {
    public var description: String {
        return cusDescription()
    }
    
    var debugDescription: String {
        return cusDescription()
    }
    
    public private(set) var id: Int
    public private(set) var requestType: ArRequestType
    
    public var event: ArRequestEvent
    public var timeout: ArRequestTimeout
    public var header: [String: String]?
    public var parameters: [String: Any]?
    public var object: ArUploadObject
    
    public init(event: ArRequestEvent,
                timeout: ArRequestTimeout = .medium,
                object: ArUploadObject,
                url: String,
                header: [String: String]? = nil,
                parameters: [String: Any]? = nil) {
        TaskId.value += 1
        self.id = TaskId.value
        self.object = object
        self.requestType = .http(.post, url: url)
        self.event = event
        self.timeout = timeout
        self.header = header
        self.parameters = parameters
    }
    
    func cusDescription() -> String {
        let dic: [String: Any] = ["object": object.description,
                                  "header": OptionsDescription.any(header),
                                  "parameters": OptionsDescription.any(parameters)]
        return dic.description
    }
}

fileprivate struct TaskId {
    static var value: Int = Date.millisecondTimestamp
}

fileprivate extension Date {
    static var millisecondTimestamp: Int {
        return Int(CACurrentMediaTime() * 1000)
    }
}

// MARK: OC Models
@objc public class ArRequestEventOC: NSObject {
    @objc public var name: String
    
    @objc public init(name: String) {
        self.name = name
    }
}

@objc public enum ArRetryOptionsOC: Int {
    case retry, resign
}

@objc public enum ArRequestTypeOC: Int {
    case http, socket
}

@objc public enum ArHTTPMethodOC: Int {
    case options
    case get
    case head
    case post
    case put
    case patch
    case delete
    case trace
    case connect
}

@objc public enum ArResponseTypeOC: Int {
    case json, data, blank
}

@objc public enum ArFileMIMEOC: Int {
    case png, zip
}

@objc public class ArRequestTypeObjectOC: NSObject {
    @objc public var type: ArRequestTypeOC
    
    @objc public init(type: ArRequestTypeOC) {
        self.type = type
    }
}

@objc public class ArRequestTypeJsonObjectOC: ArRequestTypeObjectOC {
    @objc public var method: ArHTTPMethodOC
    @objc public var url: String
    
    @objc public init(method: ArHTTPMethodOC,
                      url: String) {
        self.method = method
        self.url = url
        super.init(type: .http)
    }
}

@objc public class ArRequestTypeSocketObjectOC: ArRequestTypeObjectOC {
    @objc public var peer: String

    @objc public init(peer: String) {
        self.peer = peer
        super.init(type: .socket)
    }
}

@objc public class ArRequestTaskOC: NSObject {
    @objc public private(set) var id: Int
    @objc public var event: ArRequestEventOC
    @objc public var requestType: ArRequestTypeObjectOC
    @objc public var timeout: TimeInterval
    @objc public var header: [String : String]?
    @objc public var parameters: [String : Any]?
    
    @objc public init(event: ArRequestEventOC,
                type: ArRequestTypeObjectOC,
                timeout: TimeInterval = 10,
                header: [String: String]? = nil,
                parameters: [String: Any]? = nil) {
        TaskId.value += 1
        self.id = TaskId.value
        self.event = event
        self.requestType = type
        self.timeout = timeout
        self.header = header
        self.parameters = parameters
    }
}

@objc public class ArResponseOC: NSObject {
    @objc public var type: ArResponseTypeOC
    @objc public var json: [String: Any]?
    @objc public var data: Data?
    
    @objc public init(type: ArResponseTypeOC,
                      json: [String: Any]?,
                      data: Data?) {
        self.type = type
        self.json = json
        self.data = data
    }
}

@objc public class ArUploadObjectOC: NSObject {
    @objc public var fileKeyOnServer: String
    @objc public var fileName: String
    @objc public var fileData: Data
    @objc public var mime: ArFileMIMEOC
    
    @objc public init(fileKeyOnServer: String,
                      fileName: String,
                      fileData: Data,
                      mime: ArFileMIMEOC) {
        self.fileKeyOnServer = fileKeyOnServer
        self.fileName = fileName
        self.fileData = fileData
        self.mime = mime
    }
}

@objc public class ArUploadTaskOC: NSObject {
    @objc public private(set) var id: Int
    @objc public var event: ArRequestEventOC
    @objc public var timeout: TimeInterval
    @objc public var url: String
    @objc public var header: [String : String]?
    @objc public var parameters: [String : Any]?
    @objc public var object: ArUploadObjectOC
    
    public private(set) var requestType: ArRequestType
    
    @objc public init(event: ArRequestEventOC,
                      timeout: TimeInterval,
                      object: ArUploadObjectOC,
                      url: String,
                      header: [String: String]? = nil,
                      parameters: [String: Any]? = nil) {
        TaskId.value += 1
        self.id = TaskId.value
        self.url = url
        self.object = object
        self.requestType = .http(.post, url: url)
        self.event = event
        
        self.timeout = timeout
        self.header = header
        self.parameters = parameters
    }
}
