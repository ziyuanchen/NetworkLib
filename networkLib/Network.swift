//
//  Network.swift
//  networkLib
//
//  Created by FSMIS on 2016/3/9.
//  Copyright © 2016年 FSMIS. All rights reserved.
//

import Foundation

class Network {
    
    static func request(method: String, url: String, callback: (data: NSData!, response:NSURLResponse!, error:NSError!) ->Void) {
        
        let manager = NetworkManager(url: url, method: method, callback: callback)
        manager.fire()
    }
    
    static func request(method: String, url: String, params: Dictionary<String, AnyObject> = Dictionary<String, AnyObject>(), callback: (data:NSData!, response: NSURLResponse!, error: NSError!) -> Void) {
        
        let manager = NetworkManager(url: url, method: method, params: params, callback: callback)
        manager.fire()
    }
    
    static func request(method: String, url: String, files: Array<File>, callback: (data: NSData!, response: NSURLResponse!, error: NSError!) -> Void) {
        let manager = NetworkManager(url: url, method: method, files: files, callback: callback)
        manager.fire()
    }
    
    static func request(method: String, url: String, params: Dictionary<String, AnyObject>, files: Array<File>, callback: (data: NSData!, response: NSURLResponse!, error: NSError!) -> Void) {
        let manager = NetworkManager(url: url, method: method, params: params, files: files, callback: callback)
        manager.fire()
    }
    
    static func get(url: String, callback: (data:NSData!, response: NSURLResponse!, error:NSError!) -> Void){
        
        let manager = NetworkManager(url: url, method: "GET", callback: callback)
        manager.fire()
    }
    
    static func get(url: String, params: Dictionary<String, AnyObject>, callback:(data:NSData!, response:NSURLResponse!, error:NSError!) -> Void){
        
        let manager = NetworkManager(url: url, method: "GET", params: params, callback: callback)
        manager.fire()
    }
    
    static func post(url: String, callback: (data: NSData!, response: NSURLResponse!, error:NSError!) -> Void){
        
        let manager = NetworkManager(url: url, method: "POST", callback: callback)
        manager.fire()
    }
    
    static func post(url: String, params: Dictionary<String, AnyObject>, callback:(data:NSData!, response:NSURLResponse!,
        error:NSError!) -> Void){
            
        let manager = NetworkManager(url: url, method: "POST", params: params, callback: callback)
        manager.fire()
    }
    
}

class NetworkManager {
    let boundary = "PitayaUGl0YXlh"
    
    let method: String!
    let params: Dictionary<String, AnyObject>
    let callback: (data: NSData!, reqonse: NSURLResponse!, error: NSError!) -> Void
    
    //add files
    var files: Array<File>
    
    let session = NSURLSession.sharedSession()
    let url: String!
    var request: NSMutableURLRequest!
    var task: NSURLSessionTask!
    
    init(url: String, method: String, params: Dictionary<String, AnyObject> = Dictionary<String, AnyObject>(), files:Array<File> = Array<File>(),callback: (data: NSData!, response: NSURLResponse!, error: NSError!) -> Void) {
        
        self.url = url
        self.request = NSMutableURLRequest(URL: NSURL(string: url)!)
        self.method = method
        self.params = params
        self.callback = callback
        
        self.files = files
    }
    
    func buildRequest() {
        if self.method == "GET" && self.params.count > 0 {
            self.request = NSMutableURLRequest(URL: NSURL(string: url + "?" + buildParams(self.params))!)
        }
        
        request.HTTPMethod = self.method
        
        if self.params.count > 0 {
            request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        }
    }
    
    func buildBody() {
        let data = NSMutableData()
        if self.files.count > 0 {
            if self.method == "GET"{
                NSLog("\n\n------------------------\nThe remote server may not accept GET method with HTTP body. But Pitaya will send it anyway.\n------------------------\n\n")
            }
            for (key, value) in self.params {
                data.appendData("--\(self.boundary)\r\n" .dataUsingEncoding(NSUTF8StringEncoding)!)
                data.appendData("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
                data.appendData("\(value.description)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            }
            for file in self.files {
                data.appendData("--\(self.boundary)\r\n" .dataUsingEncoding(NSUTF8StringEncoding)!)
                data.appendData("Content-Disposition: form-data; name=\"\(file.name)\"; filename=\"\(file.url.lastPathComponent)\"\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
                if let a = NSData(contentsOfURL: file.url) {
                    data.appendData(a)
                    data.appendData("\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
                }
            }
            data.appendData("--\(self.boundary)--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        } else if self.params.count > 0 && self.method != "GET" {
            data.appendData(buildParams(self.params).dataUsingEncoding(NSUTF8StringEncoding)!)
        }
        request.HTTPBody = data
    }
    
    func fireTask() {
        task = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) -> Void in
            self.callback(data: data, reqonse: response, error: error)
        })
        task.resume()
    }
    
    func fire() {
        buildRequest()
        buildBody()
        fireTask()
    }
    
    //處理變量的三個函數
    func buildParams(parameters: [String: AnyObject]) -> String {
        var components: [(String, String)] = []
        for key in (parameters.keys).sort(<) {
            let value: AnyObject! = parameters[key]
            components += queryComponents(key, value)
        }
        
        return (components.map{ "\($0)=\($1)" } as [String]).joinWithSeparator("&")
    }
    
    func queryComponents(key: String, _ value: AnyObject) -> [(String, String)]{
        var components: [(String, String)] = []
        if let dictionary = value as? [String: AnyObject] {
            for(nestedKey, value) in dictionary {
                components += queryComponents("\(key)[\(nestedKey)]", value)
            }
        } else if let array = value as? [AnyObject] {
            for value in array {
                components += queryComponents("\(key)[]", value)
            }
        } else {
            components.append((escape(key), escape("\(value)")))
        }
        
        return components
    }
    
    func escape(string: String) -> String {
        
        let legalURLCharactersToBeEscaped: CFStringRef = ":&=;+!@#$()',*"
        return CFURLCreateStringByAddingPercentEscapes(nil, string, nil, legalURLCharactersToBeEscaped, CFStringBuiltInEncodings.UTF8.rawValue) as String
    }
}

//上傳文件
struct File {
    let name: String!
    let url: NSURL!
    init(name: String, url: NSURL) {
        self.name = name
        self.url = url
    }
}
