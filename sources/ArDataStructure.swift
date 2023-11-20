//
//  ArDataStructure.swift
//  Armin2
//
//  Created by Cavan on 2023/11/20.
//

import Foundation

// MARK: - Closure
public typealias ArDataExCompletion = ((Data) throws -> Void)
public typealias ArJsonExCompletion = (([String: Any]) throws -> Void)
public typealias ArExCompletion = (() throws -> Void)

public typealias ArDataCompletion = ((Data) -> Void)
public typealias ArJsonCompletion = (([String: Any]) -> Void)
public typealias ArCompletion = (() -> Void)

public typealias ArErrorCompletion = (Error) -> (Void)

// MARK: - Enum
public enum ArSuccessCompletion {
    case json(ArJsonExCompletion), data(ArDataExCompletion), blank(ArExCompletion)
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

@objc public enum ArHttpMethod: Int {
    case options
    case get
    case head
    case post
    case put
    case patch
    case delete
    case trace
    case connect
    
    var stringValue: String {
        switch self {
        case .options: return "OPTIONS"
        case .get    : return "GET"
        case .head   : return "HEAD"
        case .post   : return "POST"
        case .put    : return "PUT"
        case .patch  : return "PATCH"
        case .delete : return "DELETE"
        case .trace  : return "TRACE"
        case .connect: return "CONNECT"
        }
    }
}

// MARK: - Protocol
@objc public protocol ArLogTube: NSObjectProtocol {
    func log(info: String,
             extra: String?)
    func log(warning: String,
             extra: String?)
    func log(error: Error,
             extra: String?)
}
