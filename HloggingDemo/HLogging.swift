//
//  HLogging.swift
//  HloggingDemo
//
//  Created by 叶永平 on 2021/10/1.
//

import Foundation

enum HLoggingError: Error {
    case comman
    case fileError
    case writeError
}

// enum Hlogging {
//    static func write(message: String, to file: String) -> Result<Void, HLoggingError> {
//        message.withCString { msg  in
//            file.withCString { f -> Result<Void, HLoggingError> in
//                let result = write_log_file( f, msg)
//                if result == 0 {
//                    return .success(())
//                } else if result == 1 {
//                    return .failure(.fileError)
//                } else if result == 2 {
//                    return .failure(.writeError)
//                } else {
//                    return .failure(.comman)
//                }
//            }
//        }
//    }
// }
