//
//  ArProtocols.swift
//  ArProtocols
//
//  Created by CavanSu on 2019/6/19.
//  Copyright © 2019 CavanSu. All rights reserved.
//

import Foundation

public protocol ArLogTube: NSObjectProtocol {
    func log(info: String, extra: String?)
    func log(warning: String, extra: String?)
    func log(error: Error, extra: String?)
}

@objc public protocol ArLogTubeOC: NSObjectProtocol {
    func log(info: String, extra: String?)
    func log(warning: String, extra: String?)
    func log(error: ArErrorOC, extra: String?)
}

public protocol ArRequestEventProtocol: CustomStringConvertible {
    var name: String {get set}
}

public protocol ArRequestTaskProtocol {
    var id: Int {get}
    var requestType: ArRequestType {get}
    var event: ArRequestEvent {get set}
    var timeout: ArRequestTimeout {get set}
    var header: [String: String]? {get set}
    var parameters: [String: Any]? {get set}
}

public protocol ArUploadTaskProtocol: ArRequestTaskProtocol {
    var object: ArUploadObject {get set}
}

// MARK: - Request APIs
public protocol ArRequestAPIsProtocol {
    func request(task: ArRequestTaskProtocol,
                 responseOnMainQueue: Bool,
                 success: ArResponse?,
                 failRetry: ArErrorRetryCompletion)
    
    func upload(task: ArUploadTaskProtocol,
                responseOnMainQueue: Bool,
                success: ArResponse?,
                failRetry: ArErrorRetryCompletion)
}
