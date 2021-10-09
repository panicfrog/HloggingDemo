//
//  ViewController.swift
//  HloggingDemo
//
//  Created by 叶永平 on 2021/10/1.
//

import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        Log.debug(message: "hahah")
        Log.debug(message: "hahah3", metadata: .map(value: ["token" : .string(value: "saf232adkfad0jfksajckjaldfas01")]))
        Log.debug(message: "发那科放假啊圣诞快乐", metadata: .string(value: ""),  source: "ViewController")
        Log.info(message: "九分裤大酸辣粉经典款")
        Log.notice(message: "notice daklfjdaskl ", source: "ViewController")
//        write(log: "123456789 \n")
//        write(log: "abcdefghigklmnopqrst \n")
//        write(log: "uniffi \n")
    }

    func write(log: String) {
        let path = getDocumentsDirectoryPath()
        let logPath = path + "/rustio.log"
        do {
            try writeFile(filename: logPath, message: log)
        } catch {
            print(error)
        }
    }
}
