//
//  ViewController.swift
//  networkLib
//
//  Created by FSMIS on 2016/3/9.
//  Copyright © 2016年 FSMIS. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func mainButtonBeTapped(sender: AnyObject) {
        
        Network.request("GET", url: "http://221.4.149.46:8080/fsmpwebservice/main.asmx/Get_Plant", params: ["year" : "2015"]) { (data, response, error) -> Void in
            let string = NSString(data: data, encoding: NSUTF8StringEncoding)
            
            print(string)
        }
    }
}

