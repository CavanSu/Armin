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
    lazy var client = Armin(delegate: self,
                            logTube: self)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        downloadRequest()
//        stopTask()
        
    }
    
    override func touchesBegan(with event: NSEvent) {
        
    }

    override var representedObject: Any? {
        didSet {
        }
    }

    func getRequest() {
        let url = "http://t.weather.sojson.com/api/weather/city"
        let event = ArRequestEvent(name: "Sample-get")
        let task = ArRequestTask(event: event,
                               type: .http(.get, url: url),
                               timeout: .low)
        
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
    
    func downloadRequest() {
//        let urlStr = "https://img2.baidu.com/it/u=3666548066,2508071679&fm=26&fmt=auto"
        let urlStr = "https://convertcdn.netless.link/publicFiles.zip"
        let event = ArRequestEvent(name: "download-image")
        let obj = ArDownloadObject(folderPath: "/Users/doublecircle/Desktop/Armin_local",
                                   cover: false)
        let task = ArDownloadTask(event: event,
                                  object: obj,
                                  url: urlStr)
        client.download(task: task,
                        progress: { progress in
            print("----------Progress: \(progress)")
        }, success: ArResponse.string({ finalPath in
            print("----final path: \(finalPath)")
        })) { (error) -> ArRetryOptions in
            print("----error: \(error.localizedDescription)")
            return .resign
        }
    }
    
    func stopTask() {
        let urlStr = "https://convertcdn.netless.link/publicFiles.zip"
        
        client.stopTasks(urls: [urlStr])
    }
}

extension ViewController: ArminDelegate {
    func armin(_ client: Armin,
               requestSuccess event: ArRequestEvent,
               startTime: TimeInterval,
               url: String) {
        print("request success, event: \(event.description), url: \(url)")
    }
    
    func armin(_ client: Armin,
               requestFail error: ArError,
               event: ArRequestEvent,
               url: String) {
        print("request error, event: \(event.description), error: \(error.localizedDescription), url: \(url)")
    }
}

extension ViewController: ArLogTube {
    func log(info: String,
             extra: String?) {
        print("info: \(info),\n extra: \(extra ?? "nil")\n")
    }
    
    func log(warning: String,
             extra: String?) {
        print("warning: \(warning),\n extra: \(extra ?? "nil")\n")
    }
    
    func log(error: ArError,
             extra: String?) {
        print("error: \(error),\n extra: \(extra ?? "nil")\n")
    }
}
