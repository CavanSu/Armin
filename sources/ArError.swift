//
//  ArError.swift
//  Armin
//
//  Created by CavanSu on 2020/5/25.
//  Copyright © 2020 CavanSu. All rights reserved.
//

public struct ArError: Error {
    public enum ErrorType {
        case fail(String)
        case invalidParameter(String)
        case valueNil(String)
        case serialization(String)
        case convert(String, String)
        case fileExists(String)
        case taskExists(Int)
        case copyFile(String,String)
        case unknown
        
        var description: String {
            var description: String
            switch self {
            case .fail(let reason):             description = "\(reason)"
            case .invalidParameter(let para):   description = "\(para)"
            case .valueNil(let para):           description = "\(para) nil"
            case .serialization(let para):      description = "serialize \(para) fail"
            case .convert(let a, let b):        description = "\(a) converted to \(b) error"
            case .fileExists(let path):         description = "\(path) already exists"
            case .taskExists(let taskId):         description = "\(taskId) already exists"
            case .copyFile(let ori, let target):description = "copy from \(ori) to \(target) error"
            case .unknown:                      description = "unknown error"
            }
            return description
        }
    }
    
    public var localizedDescription: String {
        var description = type.description
        
        if let code = code {
            description += ", code: \(code)"
        }
        
        if let extra = extra {
            description += ", extra: \(extra)"
        }
        
        if let data = responseData,
           let dataString = String(data: data,
                                   encoding: .utf8) {
            
            description += ", data: \(dataString)"
        }
        
        return description
    }
    
    public var type: ErrorType
    public var code: Int?
    public var extra: String?
    public var responseData: Data?
    
    public static func fail(_ text: String,
                            code: Int? = nil,
                            extra: String? = nil,
                            responseData: Data? = nil) -> ArError {
        return ArError(type: .fail(text),
                       code: code,
                       extra: extra,
                       responseData: responseData)
    }
    
    public static func invalidParameter(_ text: String,
                                        code: Int? = nil,
                                        extra: String? = nil,
                                        responseData: Data? = nil) -> ArError {
        return ArError(type: .invalidParameter(text),
                       code: code,
                       extra: extra,
                       responseData: responseData)
    }
    
    public static func valueNil(_ text: String,
                                code: Int? = nil,
                                extra: String? = nil,
                                responseData: Data? = nil) -> ArError {
        return ArError(type: .valueNil(text),
                       code: code,
                       extra: extra,
                       responseData: responseData)
    }
    
    public static func convert(_ from: String,
                               _ to: String) -> ArError {
        return ArError(type: .convert(from, to))
    }
    
    public static func unknown() -> ArError {
        return ArError(type: .unknown)
    }
}
