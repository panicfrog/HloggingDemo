//
//  ViewController.swift
//  HloggingDemo
//
//  Created by 叶永平 on 2021/10/1.
//

import UIKit
import JJLISO8601DateFormatter
import Atomics

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
    private enum Formatter {
        case ISO8601, custom, jjlISO8061
    }
    
    private enum Writer {
        case outputStream, cfilehandel, filehandle
    }
    
    @IBAction func swift(_ sender: Any) {
        weiteLogPerformace()
    }
    
    private func weiteLogPerformace() {
        var filehandle: FileHandle?
        var directory: String? = .none
        let start = Date()
        if case let .fileLogger(dir) = type {
            directory = dir
            
        }
        if case let .mmapLogger(dir) = type {
            directory = dir
        }
        if let directory = directory {
            let fm = FileManager.default
            if !fm.fileExists(atPath: directory) {
                try! FileManager.default.createDirectory(at: URL(string: directory)!, withIntermediateDirectories: true, attributes: nil)
            }
            
            var charArray:[CChar] = getCurrentLogPath(from: directory).cString(using: .utf8)!
            let fd = withUnsafePointer(to: &charArray[0], { p -> Int32 in
                // 0644
                open(p, O_WRONLY|O_APPEND|O_CREAT, S_IRUSR|S_IWUSR|S_IRGRP|S_IROTH)
            })
            if fd == -1 {
                fatalError("\(#file) \(#function) \(#line) open file error")
            }
            filehandle = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
        }
        let counter = ManagedAtomic<Int>(0)
        DispatchQueue.concurrentPerform(iterations: 10) { _ in
            for i in 0..<10000 {
                let date = Date()
                let _dateFormatter = JJLISO8601DateFormatter()
                _dateFormatter.formatOptions = [_dateFormatter.formatOptions, .withFractionalSeconds]
                _dateFormatter.timeZone = TimeZone.current
                let dateString = _dateFormatter.string(from: date)
                let label = "mylogger"
                let level = "DEBUG"
                switch type {
                case .stdStream:
                    let l = "\(dateString) \(level) \(label): 人之初，性本善。性相近，习相远。苟不教，性乃迁。教之道，贵以专。昔孟母，择邻处。子不学，断机杼。窦燕山，有义方。教五子，名俱扬。养不教，父之过。教不严，师之惰。子不学，非所宜。幼不学，老何为。玉不琢，不成器。\(i)"
                    print(l)
                    break
                case .fileLogger(_), .mmapLogger(_):
                    let l = "\(dateString) \(level) \(label): 人之初，性本善。性相近，习相远。苟不教，性乃迁。教之道，贵以专。昔孟母，择邻处。子不学，断机杼。窦燕山，有义方。教五子，名俱扬。养不教，父之过。教不严，师之惰。子不学，非所宜。幼不学，老何为。玉不琢，不成器。\(i)\n"
                    filehandle!.write(l.data(using: .utf8)!)
                    break
                case .none:
                    break
                }
                counter.wrappingIncrement(ordering: .relaxed)
            }
        }
        if let filehandle = filehandle {
            try! filehandle.synchronize()
        }
        let num = counter.load(ordering: .relaxed)
        print("swift: \(num) logs total")
        let end = Date()
        let duration = end.timeIntervalSince(start)
        stdoutSwiftLabel.text = "swift: \(duration) s"
    }
    
    private func writeLog(with writer: Writer, formatter: Formatter) {
        var filehandle: FileHandle?
        var directory: String? = .none
        let start = Date()
        var outputStream: OutputStream? = nil
        if case let .fileLogger(dir) = type {
            directory = dir
        }
        if case let .mmapLogger(dir) = type {
            directory = dir
        }
        if let directory = directory {
            let fm = FileManager.default
            if !fm.fileExists(atPath: directory) {
                try! FileManager.default.createDirectory(at: URL(string: directory)!, withIntermediateDirectories: true, attributes: nil)
            }
            
            // MARK: - Filehandle
            if case .filehandle =  writer {
                filehandle = try! FileHandle(forWritingTo: getCurrentLogURL(form: directory))
            }
            
            // MARK: Filehandle create with c
            if case .cfilehandel =  writer{
                var charArray:[CChar] = getCurrentLogPath(from: directory).cString(using: .utf8)!
                let fd = withUnsafePointer(to: &charArray[0], { p -> Int32 in
                    // 0644
                    open(p, O_WRONLY|O_APPEND|O_FSYNC|O_CREAT, S_IRUSR|S_IWUSR|S_IRGRP|S_IROTH)
                })
                if fd == -1 {
                    fatalError("\(#file) \(#function) \(#line) open file error")
                }
                filehandle = FileHandle(fileDescriptor: fd, closeOnDealloc: true)
            }
            
            // MARK: OutputStream
            if case .outputStream  = writer {
                outputStream = OutputStream(url: getCurrentLogURL(form: directory), append: true)
            }
        }
        let count = 100000
        for i in 0..<count {
            let date = Date()
            let dateString = format(date: date, with: formatter)
            let label = "mylogger"
            let level = "DEBUG"
            switch type {
            case .stdStream:
                let l = "\(dateString) \(level) \(label): 人之初，性本善。性相近，习相远。苟不教，性乃迁。教之道，贵以专。昔孟母，择邻处。子不学，断机杼。窦燕山，有义方。教五子，名俱扬。养不教，父之过。教不严，师之惰。子不学，非所宜。幼不学，老何为。玉不琢，不成器。"
                print(l)
                break
            case .fileLogger(_), .mmapLogger(_):
                let l = "\(dateString) \(level) \(label): 人之初，性本善。性相近，习相远。苟不教，性乃迁。教之道，贵以专。昔孟母，择邻处。子不学，断机杼。窦燕山，有义方。教五子，名俱扬。养不教，父之过。教不严，师之惰。子不学，非所宜。幼不学，老何为。玉不琢，不成器。\n"
                
                if case .filehandle =  writer, let filehandle = filehandle {
                    try! filehandle.seekToEnd()
                    filehandle.write(l.data(using: .utf8)!)
                    try! filehandle.synchronize()
                }
                
                if case .cfilehandel =  writer, let filehandle = filehandle {
                    filehandle.write(l.data(using: .utf8)!)
                }
                
                if case .outputStream  = writer, let outputStream = outputStream {
                    if i == 0 {
                        outputStream.open()
                    }
                    let bytesWritten = outputStream.write(l, maxLength: l.count)
                    if bytesWritten < 0 { print("write failure") }
                    if i == 100000 - 1 {
                        outputStream.close()
                    } else {
                        print("Unable to open file")
                    }
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

    // MARK: -
    private func format(date: Date, with formatter: Formatter) -> String {
        switch formatter {
        // MARK: ISO8601DateFormatter
        case .ISO8601:
            let dataFormatter = ISO8601DateFormatter()
            dataFormatter.formatOptions = [dataFormatter.formatOptions, .withFractionalSeconds]
            dataFormatter.timeZone = TimeZone.current
            return dataFormatter.string(from: date)
        // MARK: Custom DateFormatter
        case .custom:
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            dateFormatter.timeZone = TimeZone.current
            return dateFormatter.string(from: date)
        // MARK: JJLISO8601DateFormatter
        case .jjlISO8061:
            let _dateFormatter = JJLISO8601DateFormatter()
            _dateFormatter.formatOptions = [_dateFormatter.formatOptions, .withFractionalSeconds]
            _dateFormatter.timeZone = TimeZone.current
            return _dateFormatter.string(from: date)
        }
    }
    // MARK: -
    
    @IBAction func rust(_ sender: Any) {
        let start = Date()
        let counter = ManagedAtomic<Int>(0)
        DispatchQueue.concurrentPerform(iterations: 10) { _ in
            for _ in 0..<10000 {
                HloggingDemo.debug(metadata: .string(value: ""), message: "人之初，性本善。性相近，习相远。苟不教，性乃迁。教之道，贵以专。昔孟母，择邻处。子不学，断机杼。窦燕山，有义方。教五子，名俱扬。养不教，父之过。教不严，师之惰。子不学，非所宜。幼不学，老何为。玉不琢，不成器。", source: nil)
                counter.wrappingIncrement(ordering: .relaxed)
            }
        }
        let num = counter.load(ordering: .relaxed)
        print("rust: \(num) logs total")
        let end = Date()
        let duration = end.timeIntervalSince(start)
        stdoutRustLabel.text = "rust: \(duration) s"
        
        //        let directory: String?
        //        if case let .fileLogger(dir) = type {
        //           directory = dir
        //        } else if case let .mmapLogger(dir) = type {
        //            directory = dir
        //        } else {
        //            directory = .none
        //        }
        //        if let directory = directory {
        //            let r = try! String(contentsOf: getCurrentLogURL(form: directory))
        //            print(r.count)
        //        }
    }
    
    func getCurrentLogURL(form directory: String) -> URL {
        let data = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyMMdd"
        let dateString = dateFormatter.string(from: data)
        return URL(string: "file://\(directory)/\(dateString).log")!
    }
    
    func getCurrentLogPath(from directory: String) -> String {
        let data = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyMMdd"
        let dateString = dateFormatter.string(from: data)
        return "\(directory)/\(dateString).log"
    }
}

