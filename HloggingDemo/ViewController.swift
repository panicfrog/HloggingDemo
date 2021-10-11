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
//        let start = Date()
        for i in 0..<145000 {
            Log.debug(message: "hahah\(i)")
        }
//        let end = Date()
//        for i in 0..<145000 {
//            let data = Date()
//            let dateFormatter = DateFormatter()
//            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
//            dateFormatter.timeZone = TimeZone.current
//            let dateString = dateFormatter.string(from: data)
//            let label = "mylogger"
//            let level = "DEBUG"
//            print("\(dateString) \(level) \(label):  hahah\(i)")
//        }
//        let end2 = Date()
//
//        let duration = end.timeIntervalSince(start)
//        let duration2 = end2.timeIntervalSince(end)
//        print("duratin1: \(duration), duration2: \(duration2)")
//        Log.debug(message: "hahah")
//        Log.debug(message: "hahah3", metadata: .array(value: [.string(value: "string"), .map(value: ["key": .string(value: "value")])]))
//        Log.debug(message: "发那科放假啊圣诞快乐", metadata: .string(value: ""),  source: "ViewController")
//        Log.info(message: "九分裤大酸辣粉经典款")
//        Log.notice(message: "notice daklfjdaskl ", source: "ViewController")
//        write(log: "123456789 \n")
//        write(log: "abcdefghigklmnopqrst \n")
//        write(log: "uniffi \n")
    }

    func write(log: String) {
        let path = getDocumentsDirectoryPath()
        let logPath = path + "/async_rust_io.log"
        do {
            try writeFile(filename: logPath, message: log)
        } catch {
            print(error)
        }
    }
}
