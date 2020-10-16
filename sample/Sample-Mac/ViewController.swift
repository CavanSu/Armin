//
//  ViewController.swift
//  Sample-Mac
//
//  Created by CavanSu on 2020/5/29.
//  Copyright © 2020 CavanSu. All rights reserved.
//

import Cocoa
import Armin

class ViewController: NSViewController {

    lazy var client = Armin(delegate: self, logTube: self)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        getRequest()
    }

    override var representedObject: Any? {
        didSet {
        }
    }

    func getRequest() {
        let url = "http://t.weather.sojson.com/api/weather/city"
        let event = RequestEvent(name: "Sample-get")
        let task = RequestTask(event: event,
                               type: .http(.get, url: url),
                               timeout: .low)
        
        client.request(task: task, success: ACResponse.json({ (json) in
            print("weather json: \(json.description)")
        })) { (error) -> RetryOptions in
            print("error: \(error.localizedDescription)")
            return .resign
        }
    }
    
    func postRequest() {
        let url = ""
        let event = RequestEvent(name: "Sample-post")
        let parameters: [String: Any]? = nil
        let headers: [String: String]? = nil
        let task = RequestTask(event: event,
                               type: .http(.post, url: url),
                               timeout: .low,
                               header: headers,
                               parameters: parameters)
        
        client.request(task: task, success: ACResponse.json({ (json) in
            print("weather json: \(json.description)")
        })) { (error) -> RetryOptions in
            print("error: \(error.localizedDescription)")
            return .resign
        }
    }
}

extension ViewController: ArminDelegate {
    func alamo(_ client: Armin, requestSuccess event: ACRequestEvent, startTime: TimeInterval, url: String) {
        print("request success, event: \(event.description), url: \(url)")
    }
    
    func alamo(_ client: Armin, requestFail error: ACError, event: ACRequestEvent, url: String) {
        print("request error, event: \(event.description), error: \(error.localizedDescription), url: \(url)")
    }
}

extension ViewController: ACLogTube {
    func log(from: AnyClass, info: String, extral: String?, funcName: String) {
        print("info: \(info), extra: \(extral ?? "nil"), funcName: \(funcName)")
    }
    
    func log(from: AnyClass, warning: String, extral: String?, funcName: String) {
        print("warning: \(warning), extra: \(extral ?? "nil"), funcName: \(funcName)")
    }
    
    func log(from: AnyClass, error: Error, extral: String?, funcName: String) {
        print("error: \(error), extra: \(extral ?? "nil"), funcName: \(funcName)")
    }
}
