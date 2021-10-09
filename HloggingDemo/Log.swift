//
//  Log.swift
//  HloggingDemo
//
//  Created by 叶永平 on 2021/10/9.
//

import Foundation

enum Log {
    static func debug(message: String, metadata: Metadata = .string(value: ""), source: String? = nil) {
        HloggingDemo.debug(metadata: metadata, message: message, source: source)
    }
    static func info(message: String, metadata: Metadata = .string(value: ""), source: String? = nil) {
        HloggingDemo.info(metadata: metadata, message: message, source: source)
    }
    static func notice(message: String, metadata: Metadata = .string(value: ""), source: String? = nil) {
        HloggingDemo.notice(metadata: metadata, message: message, source: source)
    }
    static func warring(message: String, metadata: Metadata = .string(value: ""), source: String? = nil) {
        HloggingDemo.warring(metadata: metadata, message: message, source: source)
    }
    static func error(message: String, metadata: Metadata = .string(value: ""), source: String? = nil) {
        HloggingDemo.error(metadata: metadata, message: message, source: source)
    }
    static func critical(message: String, metadata: Metadata = .string(value: ""), source: String? = nil) {
        HloggingDemo.critical(metadata: metadata, message: message, source: source)
    }
}
