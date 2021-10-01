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
        write(log: "123456789 \n")
        write(log: "abcdefghigklmnopqrst \n")
        write(log: "一二三四五六七八九十 \n")
    }
    
    func write(log: String) {
        let path = getDocumentsDirectoryPath()
        let logPath = path + "/rustio.log"
        guard case .success = Hlogging.write(message: log, to: logPath) else {
            return
        }
    }

}

