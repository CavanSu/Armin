//
//  ACUtils.swift
//  Armin
//
//  Created by CavanSu on 2020/5/25.
//  Copyright © 2020 CavanSu. All rights reserved.
//

import Foundation

struct OptionsDescription {
    static func any<any>(_ any: any?) -> String where any: CustomStringConvertible {
        return any != nil ? any!.description : "nil"
    }
}

class AfterWorker {
    private var pendingRequestWorkItem: DispatchWorkItem?
    
    func perform(after: TimeInterval,
                 on queue: DispatchQueue,
                 _ block: @escaping (() -> Void)) {
        // Cancel the currently pending item
        pendingRequestWorkItem?.cancel()
        
        // Wrap our request in a work item
        let requestWorkItem = DispatchWorkItem(block: block)
        pendingRequestWorkItem = requestWorkItem
        queue.asyncAfter(deadline: .now() + after, execute: requestWorkItem)
    }
    
    func cancel() {
        pendingRequestWorkItem?.cancel()
    }
}

class ArFileHandler {
    func generateFilePath(cover: Bool = true,
                          fileLocation: String,
                          directoryPath: String) throws -> String? {
        guard FileManager.default.fileExists(atPath: fileLocation) else {
            // 目标文件不存在
            throw ArError(type: .valueNil("fileLocation:\(fileLocation)"))
        }
        
        let subArr = fileLocation.split(separator: "/")
        guard subArr.count > 0,
              let fileName = subArr.last else {
                  // 目标文件路径有误
                  throw ArError(type: .invalidParameter("directoryPath:\(directoryPath)"))
              }
        
        if !FileManager.default.fileExists(atPath: directoryPath),
           let url = URL(string: directoryPath) {
            do {
                try FileManager.default.createDirectory(at: url,
                                                        withIntermediateDirectories: true,
                                                        attributes: nil)
            } catch {
                // 创建文件夹失败
                throw ArError(type: .invalidParameter("directoryPath:\(directoryPath),error:\(error)"))
            }
        }
        
        let path = directoryPath.appending("/\(fileName)")
        if FileManager.default.fileExists(atPath: path) {
            if cover,
               let fileUrl = URL(string: path) {
                // 文件存在，删除已存在文件
                try? FileManager.default.removeItem(at: fileUrl)
                return path
            } else {
                // 文件存在，不覆盖，抛错
                throw ArError(type: .fileExists(path))
            }
        }
        return path
    }
    
    func copyFile(filePath: String,
                  targetPath: String) throws {
        // Move file
        do {
            try FileManager.default.copyItem(atPath: filePath,
                                             toPath: targetPath)
        } catch{
            let err = error as NSError
            throw ArError(type: .copyFile(filePath,
                                          targetPath),
                          code: err.code,
                          extra: err.localizedDescription)
        }
        
    }
}

// MARK: extension
extension URLRequest {
    mutating func makeHeaders(headers: [String: String]?) {
        guard let headersDic = headers else {
            return
        }
        
        for (k,v) in headersDic {
            self.setValue(v,
                          forHTTPHeaderField: k)
        }
    }
    
    // TODO: not work
    mutating func makeBody(parameters: [String: Any]?) {
        if let params = parameters {
            let JSONArr = NSMutableArray()
            for (k,v) in params {
                let valueStr = toString(key: k,value: v)
                JSONArr.add("\(k)\("=")\(valueStr)")
            }
            let data = JSONArr.componentsJoined(by: "&").data(using: .utf8)
            self.httpBody = data
        }
    }
    
    // TODO: not work
    func toString(key: String,
                  value: Any) -> String {
        var dicStr = ""
        if let valueDic = value as? [String: Any] {
            for(k,v) in valueDic {
                return toString(key: k,
                                value: v)
            }
        } else if let valueArr  = value as? Array<Any> {
            let valueStr = toString(key: key,
                                    value: valueArr)
            dicStr = "\(key)\("=")\(valueStr)"
        } else if let valueStr = value as? String {
            dicStr = valueStr
        }
        return dicStr
    }
}
extension Data {
    func json() throws -> [String: Any] {
        let object = try JSONSerialization.jsonObject(with: self, options: [])
        guard let dic = object as? [String: Any] else {
            throw ArError.convert("Any", "[String: Any]")
        }
        
        return dic
    }
}

extension Date {
    static var millisecondTimestamp: Int {
        return Int(CACurrentMediaTime() * 1000)
    }
}

