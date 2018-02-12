//
//  ViewController.swift
//  WebViewDemo
//
//  Created by zhangyou04 on 2018/2/12.
//  Copyright © 2018年 zhangyou. All rights reserved.
//

import UIKit
import AddressBook
import AddressBookUI

class ViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var navBackBtn: UIBarButtonItem!
    @IBOutlet weak var navAddBtn: UIBarButtonItem!
    @IBOutlet weak var segmentedBtn: UISegmentedControl!
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var loading: UIActivityIndicatorView!

    var listContacts: NSArray!
    
    @IBAction func onBack(_ sender: Any) {
        self.webView.goBack();
    }
    
    @IBAction func onAdd(_ sender: Any) {
    
    }
    
    @IBAction func segmentedBtnChange(_ sender: Any) {
        let value = self.segmentedBtn.selectedSegmentIndex
        switch value {
        case 0:
            self.loadHTMLString(path: "index")
            break
        default:
            self.loadRequest(url: "https://boxnovel.baidu.com/boxnovel/boy?ua=1242_2208_iphone_8.4.0.0_0")
            break
        }
    }
    
    // 加载本地 html
    func loadHTMLString(path: String) {
        let htmlPath = Bundle.main.path(forResource: path, ofType: "html")
        let bundleUrl = Bundle.main.bundleURL
        let html: String?
        
        do {
            html = try String(contentsOfFile: htmlPath!, encoding: String.Encoding.utf8)
            
        } catch {
            html = nil
        }
        
        if (html != nil) {
            self.webView.loadHTMLString(html!, baseURL: bundleUrl)
        }
    }
    
    // 加载远程地址
    func loadRequest(url: String) {
        let request = URLRequest(url: URL(string: url)!)
        self.webView.loadRequest(request)
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        let url = request.url
        print("捕获请求：" + (url?.absoluteString)!)
        
        let schema = url?.scheme
        let method = url?.host
        let query = url?.query
        
        if (url != nil && schema == "hybrid") {
            let queryDict: [String: String] = self.queryToDict(query: query!)
            let excuteCallback = {(json: String) -> Void in
                DispatchQueue.main.async {
                    print(queryDict["callback"]! + "(" + json + ")")
                    self.webView.stringByEvaluatingJavaScript(from: queryDict["callback"]! + "(" + json + ")")
                }
            }
            
            switch method! {
            case "getData":
                self.getData(query: queryDict, callback: excuteCallback)
                break
            case "putData":
                self.putData(query: queryDict)
                break
            case "goToWebView":
                self.gotoWebView(query: queryDict)
                break
            case "gotoNative":
                self.gotoNative(query: queryDict)
                break
            case "doAction":
                self.doAction(query: queryDict)
                break
            default:
                print(queryDict)
            }
            
            return false
        }
        
        return true
    }
    
    
    func getData(query: [String: String], callback: @escaping (_ json: String) -> Void) {
        print("getData")
        
        switch query["key"] {
        case "contacts"?:
            self.getContacts(callback: callback)
            break
        default:
            self.getContacts(callback: callback)
        }
        self.getContacts(callback: callback)
    }
    
    func getContacts(callback: @escaping (_ json: String) -> Void) {
        var addressBook: ABAddressBook!
        var error: Unmanaged<CFError>? = nil
        
        if let unmanagedAddressBook = ABAddressBookCreateWithOptions(nil, &error) {
            addressBook = unmanagedAddressBook.takeRetainedValue() as ABAddressBook
            
            ABAddressBookRequestAccessWithCompletion(addressBook,
                {
                    (success, error) -> Void in
                    if success {
                        // 查询所有
                        self.filterContentForSearchText(searchText: "")
                        print("success")
                        let json: String = self.contacts2json(contacts: self.listContacts)
                        print(json)
                        //                    self.webView.stringByEvaluatingJavaScriptFromString("JSBrige.getContacts(" + json + ")")
                        callback(json)
                        
                    } else {
                        print(error as Any)
                    }
                }
            )
        }
    }
    
    func queryToDict(query: String) -> [String: String] {
        var dict = [String: String]()
        
        let items = query.split(separator: "&").map(String.init)
        for item in items {
            var pairs = item.split(separator: "=").map(String.init)
            dict[pairs[0]] = pairs[1]
        }
        
        return dict
    }
    
    func contacts2json(contacts: NSArray) -> String {
        var list = [AnyObject]()
        var dict = [String: String]()
        
        for contact in contacts {
            if let unmanagedFirstName = ABRecordCopyValue(contact as ABRecord, kABPersonFirstNameProperty) {
                dict["firstName"] = unmanagedFirstName.takeRetainedValue() as? String
            }
            
            if let unmanagedLastName = ABRecordCopyValue(contact as ABRecord, kABPersonLastNameProperty) {
                dict["lastName"] = unmanagedLastName.takeRetainedValue() as? String
            }
            
            if let unmanagedEmail = ABRecordCopyValue(contact as ABRecord, kABPersonMiddleNameProperty) {
                dict["middleName"] = unmanagedEmail.takeRetainedValue() as? String
            }
            
            list.append(dict as AnyObject)
        }
        
        let data = try? JSONSerialization.data(withJSONObject: list, options: JSONSerialization.WritingOptions.prettyPrinted)
        let json = NSString(data: data!, encoding: String.Encoding.utf8.rawValue);
        
        return json! as String
    }
    
    func filterContentForSearchText(searchText: NSString) {
        // 如果没有授权，则退出
        if (ABAddressBookGetAuthorizationStatus() != ABAuthorizationStatus.authorized) {
            print("no Authorized")
            return
        }
        
        var error: Unmanaged<CFError>? = nil
        var addressBook: ABAddressBook!
        
        if let unmanageAddressBook = ABAddressBookCreateWithOptions(nil, &error) {
            addressBook = unmanageAddressBook.takeRetainedValue() as ABAddressBook
            
            if (searchText.length == 0) {
                // 查询所有
                self.listContacts = ABAddressBookCopyArrayOfAllPeople(addressBook).takeRetainedValue() as NSArray
            }
            else {
                // 查询条件
                self.listContacts = ABAddressBookCopyPeopleWithName(addressBook, searchText).takeRetainedValue() as NSArray
            }
        }
    }
    
    func putData(query: [String: String]) {
        print("putData")
    }
    
    func gotoWebView(query: [String: String]) {
        print("gotoWebView" + query["key"]!)
        let path = query["key"]
        
        if (path?.starts(with: "http"))! {
            self.loadRequest(url: path!)
        } else {
            self.loadHTMLString(path: path!)
        }
    }
    
    func gotoNative(query: [String: String]) {
        print("gotoNative")
    }
    
    func doAction(query: [String: String]) {
        print("doAction")
    }
    
    // webview 开始加载
    func webViewDidStartLoad(_ webView: UIWebView) {
        print("WebView开始加载...")
        self.loading.isHidden = false
    }
    
    // webview 加载完成
    func webViewDidFinishLoad(_ webView: UIWebView) {
        print("WebView加载完成:" + self.webView.stringByEvaluatingJavaScript(from: "document.title")!)
        self.loading.isHidden = true
        
        // native 调用js sayHello方法
        let msg: String = "Hello from native"
        self.webView.stringByEvaluatingJavaScript(from: "JSBrige.sayHello('" + msg + "')");
        print("JSBrige.sayHello('" + msg + "')")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.webView.delegate = self
        self.loadHTMLString(path: "index")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

