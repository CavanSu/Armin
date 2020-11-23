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
        case convert(String, String)
        case unknown
    }
    
    public var localizedDescription: String {
        var description: String
        switch type {
        case .fail(let reason):             description = "\(reason)"
        case .invalidParameter(let para):   description = "\(para)"
        case .valueNil(let para):           description = "\(para) nil"
        case .convert(let a, let b):        description = "\(a) converted to \(b) error"
        case .unknown:                      description = "unknown error"
        }
        
        if let code = code {
            description += ", code: \(code)"
        }
        
        if let extra = extra {
            description += ", extra: \(extra)"
        }
        
        return description
    }
    
    public var type: ErrorType
    public var code: Int?
    public var extra: String?
    
    public static func fail(_ text: String,
                            code: Int? = nil,
                            extra: String? = nil) -> ArError {
        return ArError(type: .fail(text),
                       code: code,
                       extra: extra)
    }
    
    public static func invalidParameter(_ text: String,
                                        code: Int? = nil,
                                        extra: String? = nil) -> ArError {
        return ArError(type: .invalidParameter(text),
                       code: code,
                       extra: extra)
    }
    
    public static func valueNil(_ text: String,
                                code: Int? = nil,
                                extra: String? = nil) -> ArError {
        return ArError(type: .valueNil(text),
                       code: code,
                       extra: extra)
    }
    
    public static func convert(_ from: String,
                               _ to: String) -> ArError {
        return ArError(type: .convert(from, to))
    }
    
    public static func unknown() -> ArError {
        return ArError(type: .unknown)
    }
}
