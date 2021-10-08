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
        debug(metadata: .string(value: "metadata"), message: "hahah", source: nil)
        debug(metadata: .string(value: "metadata"), message: "hahah3", source: nil)
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
