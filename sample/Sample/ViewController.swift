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
    lazy var client = ArminClient(logTube: self)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getRequest()
    }
    
    func getRequest() {
        let url = "https://www.tianqapi.com/api"
        
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
                       retryCount: 5,
                       success: success) { error in
            print("error: \(error.localizedDescription)")
        }
    }
}

extension ViewController: ArLogTube {
    func onLog(info: String,
               extra: [String : Any]?) {
        print(">>>>>>>>>>>>>>>>>>>>")
        print("info: \(info), extra: \(extra ?? "nil")")
        print(">>>>>>>>>>>>>>>>>>>>")
    }
    
    func onLog(warning: String,
               extra: [String : Any]?) {
        print(">>>>>>>>>>>>>>>>>>>>")
        print("warning: \(warning), extra: \(extra ?? "nil")")
        print(">>>>>>>>>>>>>>>>>>>>")
    }
    
    func onLog(error: Error,
               extra: [String : Any]?) {
        print(">>>>>>>>>>>>>>>>>>>>")
        print("error: \(error), extra: \(extra ?? "nil")")
        print(">>>>>>>>>>>>>>>>>>>>")
    }
}
