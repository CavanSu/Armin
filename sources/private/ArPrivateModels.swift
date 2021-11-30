//
//  ArPrivateModels.swift
//  Pods
//
//  Created by LYY on 2021/11/11.
//

import Foundation

struct ArTaskHandler {
    var task: ArRequestTaskProtocol
    var sessionTask: URLSessionTask
    var urlStr: String
    var responseQueue: DispatchQueue
    var startTime: TimeInterval
    
    var progress: ArDownloadProgress
    var success: ArResponse?
    var requestFail: ArErrorCompletion
}

struct ArMultipartFormDataRequest {
    private let boundary: String = UUID().uuidString
    private var httpBody = NSMutableData()
    
    let url: URL
    let timeout: ArRequestTimeout
    let method: ArHttpMethod

    init(method: ArHttpMethod,
         url: URL,
         timeout: ArRequestTimeout) {
        self.url = url
        self.timeout = timeout
        self.method = method
    }
    
    func toURLRequest() -> URLRequest {
        var request = URLRequest(url: url,
                                 timeoutInterval: timeout.value)

        request.httpMethod = method.stringValue
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        httpBody.append("--\(boundary)--")
        request.httpBody = httpBody as Data
        return request
    }

    func addTextField(named name: String,
                      value: String) {
        let str = textFormField(named: name,
                                value: value)
        httpBody.append(str)
    }

    func addDataField(named name: String,
                      data: Data,
                      mimeType: String) {
        let data = dataFormField(named: name,
                                 data: data,
                                 mimeType: mimeType)
        httpBody.append(data)
    }
}

// MARK: - private
extension ArMultipartFormDataRequest {
    private func textFormField(named name: String,
                               value: String) -> String {
        var fieldString = "--\(boundary)\r\n"
        fieldString += "Content-Disposition: form-data; name=\"\(name)\"\r\n"
        fieldString += "Content-Type: text/plain; charset=ISO-8859-1\r\n"
        fieldString += "Content-Transfer-Encoding: 8bit\r\n"
        fieldString += "\r\n"
        fieldString += "\(value)\r\n"

        return fieldString
    }

    private func dataFormField(named name: String,
                               data: Data,
                               mimeType: String) -> Data {
        let fieldData = NSMutableData()

        fieldData.append("--\(boundary)\r\n")
        fieldData.append("Content-Disposition: form-data; name=\"\(name)\"\r\n")
        fieldData.append("Content-Type: \(mimeType)\r\n")
        fieldData.append("\r\n")
        fieldData.append(data)
        fieldData.append("\r\n")

        return fieldData as Data
    }
}

extension NSMutableData {
  func append(_ string: String) {
    if let data = string.data(using: .utf8) {
      self.append(data)
    }
  }
}
