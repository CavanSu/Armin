//
//  ViewController.swift
//  Sample
//
//  Created by CavanSu on 2020/5/25.
//  Copyright © 2020 CavanSu. All rights reserved.
//

import UIKit
import Armin

class ViewController: UIViewController {
    lazy var client = Armin(delegate: self,
                            logTube: self)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getRequest()
    }
    
    func getRequest() {
        let url = "https://www.tianqiapi.com/api"
        let event = ArRequestEvent(name: "Sample-get")
        let task = ArRequestTask(event: event,
                                 type: .http(.get, url: url),
                                 timeout: .low,
                                 parameters: ["appid": "23035354",
                                              "appsecret": "8YvlPNrz",
                                              "version": "v9",
                                              "cityid": "0",
                                              "city": "%E9%9D%92%E5%B2%9B",
                                              "ip": "0",
                                              "callback": "0"])
        
        client.request(task: task, success: ArResponse.json({ (json) in
            print("weather json: \(json.description)")
        })) { (error) -> ArRetryOptions in
            print("error: \(error.localizedDescription)")
            return .resign
        }
    }
    
    func postRequest() {
        let url = ""
        let event = ArRequestEvent(name: "Sample-post")
        let parameters: [String: Any]? = nil
        let headers: [String: String]? = nil
        let task = ArRequestTask(event: event,
                               type: .http(.post, url: url),
                               timeout: .low,
                               header: headers,
                               parameters: parameters)
        
        client.request(task: task, success: ArResponse.json({ (json) in
            print("weather json: \(json.description)")
        })) { (error) -> ArRetryOptions in
            print("error: \(error.localizedDescription)")
            return .resign
        }
    }
}

extension ViewController: ArminDelegate {
    func armin(_ client: Armin,
               requestSuccess event: ArRequestEvent,
               startTime: TimeInterval, url: String) {
        print("request success, event: \(event.description), url: \(url)")
    }
    
    func armin(_ client: Armin,
               requestFail error: ArError,
               event: ArRequestEvent, url: String) {
        print("request error, event: \(event.description), error: \(error.localizedDescription), url: \(url)")
    }
}

extension ViewController: ArLogTube {
    func log(info: String,
             extra: String?) {
        print("info: \(info), extra: \(extra ?? "nil")")
    }
    
    func log(warning: String,
             extra: String?) {
        print("warning: \(warning), extra: \(extra ?? "nil")")
    }
    
    func log(error: Error,
             extra: String?) {
        print("error: \(error), extra: \(extra ?? "nil")")
    }
}
