//
//  ViewController.swift
//  HloggingDemo
//
//  Created by 叶永平 on 2021/10/1.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var stdoutSwiftLabel: UILabel!
    @IBOutlet weak var stdoutRustLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    @IBAction func swift(_ sender: Any) {
        let start = Date()
        var f = URL(string: getDocumentsDirectoryPath())!
        var outputStream: OutputStream? = nil
        if case let .fileLogger(directory) = type {
            let fm = FileManager.default
            let data = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyMMdd"
            let dateString = dateFormatter.string(from: data)
            if !fm.fileExists(atPath: directory) {
                try! FileManager.default.createDirectory(at: URL(string: directory)!, withIntermediateDirectories: true, attributes: nil)
            }
            f = URL(string: "file://\(directory)/\(dateString).log")!
            outputStream = OutputStream(url: f, append: true)
        }
        for i in 0..<100000 {
            let data = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            dateFormatter.timeZone = TimeZone.current
            let dateString = dateFormatter.string(from: data)
            let label = "mylogger"
            let level = "DEBUG"
            let l = "\(dateString) \(level) \(label):  hahah\(i) "
            switch type {
            case .stdStream:
                print(l)
                break
            case .fileLogger(_), .mmapLogger(_):
                if let outputStream = outputStream {
                    if i == 0 {
                        outputStream.open()
                    }
                    let bytesWritten = outputStream.write(l, maxLength: l.count)
                    if bytesWritten < 0 { print("write failure") }
                    if i == 100000 - 1 {
                        outputStream.close()
                    }
                } else {
                    print("Unable to open file")
                }
                break
            case .none:
                break
            }
            
        }
        let end = Date()
        let duration = end.timeIntervalSince(start)
        stdoutSwiftLabel.text = "swift: \(duration) s"
    }
    
    @IBAction func rust(_ sender: Any) {
        let start = Date()
        for i in 0..<100000 {
            Log.debug(message: "hahah\(i)")
        }
        let end = Date()
        let duration = end.timeIntervalSince(start)
        stdoutRustLabel.text = "rust: \(duration) s"
    }
    
}
