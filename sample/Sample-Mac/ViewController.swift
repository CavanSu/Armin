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
    lazy var client = ArminClient(logTube: self)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        getRequest()
    }

    override var representedObject: Any? {
        didSet {
        }
    }

    func getRequest() {
        let url = "https://www.tianqiapi.com/api"
        
        let parameters = ["appid": "23035354",
                          "appsecret": "8YvlPNrz",
                          "version": "v9",
                          "cityid": "0",
                          "city": "%E9%9D%92%E5%B2%9B",
                          "ip": "0",
                          "callback": "0"]
        
        let success = ArSuccessCompletion.json { json in
            print("weather json: \(json.description)")
        }
        
        client.request(url: url, parameters: parameters,
                       method: .get,
                       event: "Sample-get",
                       success: success) { error in
            print("error: \(error.localizedDescription)")
        }
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
