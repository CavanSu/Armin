//
//  ArRequestGenerator.swift
//  Armin
//
//  Created by LYY on 2021/11/22.
//

import Foundation

class ArRequestMaker {
    func makeRequest(urlstr: String,
                     timeout: TimeInterval,
                     method: ArHttpMethod,
                     headers: [String: String]?,
                     params: [String: Any]?) throws -> URLRequest {

        // url
        guard let url = makeUrl(urlstr: urlstr,
                                httpMethod: method,
                                parameters: params) else {
            throw ArError(type: .invalidParameter("params"))
        }
        
        var request = URLRequest(url: url,
                                 timeoutInterval: timeout)
        request.httpMethod = method.stringValue
        // header
        request.makeHeaders(headers: headers)
        
        // body
        do{
            try request.makeBody(httpMethod: method,
                                 parameters: params)
        } catch {
            throw error as! ArError
        }
        
        return request
    }
    
    func makeUrl(urlstr: String,
                 httpMethod: ArHttpMethod,
                 parameters: Dictionary<String, Any>?) -> URL? {
        var urlString = urlstr
        guard [ArHttpMethod.get,
               ArHttpMethod.head,
               ArHttpMethod.delete].contains(httpMethod),
              let params = parameters else {
            return URL(string:urlString.urlEncoded())
        }
        
        guard let url = URL(string:urlString.urlEncoded()) else {
            return nil
        }

        let JSONArr: NSMutableArray = NSMutableArray()
//        for key in params.keys {
//            let JSONString = ("\(key)\("=")\(params[key] as! String)")
//            JSONArr.add(JSONString)
//        }
        let paramStr = JSONArr.componentsJoined(by:"&")
        urlString.append("?" + paramStr)

        return URL(string:urlString.urlEncoded())
    }
}
