// This file was autogenerated by some hot garbage in the `uniffi` crate.
// Trust me, you don't want to mess with it!

import Foundation

// Depending on the consumer's build setup, the low-level FFI code
// might be in a separate module, or it might be compiled inline into
// this module. This is a bit of light hackery to work with both.
#if canImport(hloggingFFI)
    import hloggingFFI
#endif

private extension RustBuffer {
    // Allocate a new buffer, copying the contents of a `UInt8` array.
    init(bytes: [UInt8]) {
        let rbuf = bytes.withUnsafeBufferPointer { ptr in
            try! rustCall { ffi_hlogging_df33_rustbuffer_from_bytes(ForeignBytes(bufferPointer: ptr), $0) }
        }
        self.init(capacity: rbuf.capacity, len: rbuf.len, data: rbuf.data)
    }

    // Frees the buffer in place.
    // The buffer must not be used after this is called.
    func deallocate() {
        try! rustCall { ffi_hlogging_df33_rustbuffer_free(self, $0) }
    }
}

private extension ForeignBytes {
    init(bufferPointer: UnsafeBufferPointer<UInt8>) {
        self.init(len: Int32(bufferPointer.count), data: bufferPointer.baseAddress)
    }
}

// For every type used in the interface, we provide helper methods for conveniently
// lifting and lowering that type from C-compatible data, and for reading and writing
// values of that type in a buffer.

// Helper classes/extensions that don't change.
// Someday, this will be in a libray of its own.

private extension Data {
    init(rustBuffer: RustBuffer) {
        // TODO: This copies the buffer. Can we read directly from a
        // Rust buffer?
        self.init(bytes: rustBuffer.data!, count: Int(rustBuffer.len))
    }
}

// A helper class to read values out of a byte buffer.
private class Reader {
    let data: Data
    var offset: Data.Index

    init(data: Data) {
        self.data = data
        offset = 0
    }

    // Reads an integer at the current offset, in big-endian order, and advances
    // the offset on success. Throws if reading the integer would move the
    // offset past the end of the buffer.
    func readInt<T: FixedWidthInteger>() throws -> T {
        let range = offset ..< offset + MemoryLayout<T>.size
        guard data.count >= range.upperBound else {
            throw UniffiInternalError.bufferOverflow
        }
        if T.self == UInt8.self {
            let value = data[offset]
            offset += 1
            return value as! T
        }
        var value: T = 0
        _ = withUnsafeMutableBytes(of: &value) { data.copyBytes(to: $0, from: range) }
        offset = range.upperBound
        return value.bigEndian
    }

    // Reads an arbitrary number of bytes, to be used to read
    // raw bytes, this is useful when lifting strings
    func readBytes(count: Int) throws -> [UInt8] {
        let range = offset ..< (offset + count)
        guard data.count >= range.upperBound else {
            throw UniffiInternalError.bufferOverflow
        }
        var value = [UInt8](repeating: 0, count: count)
        value.withUnsafeMutableBufferPointer { buffer in
            data.copyBytes(to: buffer, from: range)
        }
        offset = range.upperBound
        return value
    }

    // Reads a float at the current offset.
    @inlinable
    func readFloat() throws -> Float {
        return Float(bitPattern: try readInt())
    }

    // Reads a float at the current offset.
    @inlinable
    func readDouble() throws -> Double {
        return Double(bitPattern: try readInt())
    }

    // Indicates if the offset has reached the end of the buffer.
    @inlinable
    func hasRemaining() -> Bool {
        return offset < data.count
    }
}

// A helper class to write values into a byte buffer.
private class Writer {
    var bytes: [UInt8]
    var offset: Array<UInt8>.Index

    init() {
        bytes = []
        offset = 0
    }

    func writeBytes<S>(_ byteArr: S) where S: Sequence, S.Element == UInt8 {
        bytes.append(contentsOf: byteArr)
    }

    // Writes an integer in big-endian order.
    //
    // Warning: make sure what you are trying to write
    // is in the correct type!
    func writeInt<T: FixedWidthInteger>(_ value: T) {
        var value = value.bigEndian
        withUnsafeBytes(of: &value) { bytes.append(contentsOf: $0) }
    }

    @inlinable
    func writeFloat(_ value: Float) {
        writeInt(value.bitPattern)
    }

    @inlinable
    func writeDouble(_ value: Double) {
        writeInt(value.bitPattern)
    }
}

// Types conforming to `Serializable` can be read and written in a bytebuffer.
private protocol Serializable {
    func write(into: Writer)
    static func read(from: Reader) throws -> Self
}

// Types confirming to `ViaFfi` can be transferred back-and-for over the FFI.
// This is analogous to the Rust trait of the same name.
private protocol ViaFfi: Serializable {
    associatedtype FfiType
    static func lift(_ v: FfiType) throws -> Self
    func lower() -> FfiType
}

// Types conforming to `Primitive` pass themselves directly over the FFI.
private protocol Primitive {}

private extension Primitive {
    typealias FfiType = Self

    static func lift(_ v: Self) throws -> Self {
        return v
    }

    func lower() -> Self {
        return self
    }
}

// Types conforming to `ViaFfiUsingByteBuffer` lift and lower into a bytebuffer.
// Use this for complex types where it's hard to write a custom lift/lower.
private protocol ViaFfiUsingByteBuffer: Serializable {}

private extension ViaFfiUsingByteBuffer {
    typealias FfiType = RustBuffer

    static func lift(_ buf: RustBuffer) throws -> Self {
        let reader = Reader(data: Data(rustBuffer: buf))
        let value = try Self.read(from: reader)
        if reader.hasRemaining() {
            throw UniffiInternalError.incompleteData
        }
        buf.deallocate()
        return value
    }

    func lower() -> RustBuffer {
        let writer = Writer()
        write(into: writer)
        return RustBuffer(bytes: writer.bytes)
    }
}

// Implement our protocols for the built-in types that we use.

extension Optional: ViaFfiUsingByteBuffer, ViaFfi, Serializable where Wrapped: Serializable {
    fileprivate static func read(from buf: Reader) throws -> Self {
        switch try buf.readInt() as Int8 {
        case 0: return nil
        case 1: return try Wrapped.read(from: buf)
        default: throw UniffiInternalError.unexpectedOptionalTag
        }
    }

    fileprivate func write(into buf: Writer) {
        guard let value = self else {
            buf.writeInt(Int8(0))
            return
        }
        buf.writeInt(Int8(1))
        value.write(into: buf)
    }
}

extension Array: ViaFfiUsingByteBuffer, ViaFfi, Serializable where Element: Serializable {
    fileprivate static func read(from buf: Reader) throws -> Self {
        let len: Int32 = try buf.readInt()
        var seq = [Element]()
        seq.reserveCapacity(Int(len))
        for _ in 0 ..< len {
            seq.append(try Element.read(from: buf))
        }
        return seq
    }

    fileprivate func write(into buf: Writer) {
        let len = Int32(count)
        buf.writeInt(len)
        for item in self {
            item.write(into: buf)
        }
    }
}

extension Dictionary: ViaFfiUsingByteBuffer, ViaFfi, Serializable where Key == String, Value: Serializable {
    fileprivate static func read(from buf: Reader) throws -> Self {
        let len: Int32 = try buf.readInt()
        var dict = [String: Value]()
        dict.reserveCapacity(Int(len))
        for _ in 0 ..< len {
            dict[try String.read(from: buf)] = try Value.read(from: buf)
        }
        return dict
    }

    fileprivate func write(into buf: Writer) {
        let len = Int32(count)
        buf.writeInt(len)
        for (key, value) in self {
            key.write(into: buf)
            value.write(into: buf)
        }
    }
}

extension String: ViaFfi {
    fileprivate typealias FfiType = RustBuffer

    fileprivate static func lift(_ v: FfiType) throws -> Self {
        defer {
            try! rustCall { ffi_hlogging_df33_rustbuffer_free(v, $0) }
        }
        if v.data == nil {
            return String()
        }
        let bytes = UnsafeBufferPointer<UInt8>(start: v.data!, count: Int(v.len))
        return String(bytes: bytes, encoding: String.Encoding.utf8)!
    }

    fileprivate func lower() -> FfiType {
        return utf8CString.withUnsafeBufferPointer { ptr in
            // The swift string gives us int8_t, we want uint8_t.
            ptr.withMemoryRebound(to: UInt8.self) { ptr in
                // The swift string gives us a trailing null byte, we don't want it.
                let buf = UnsafeBufferPointer(rebasing: ptr.prefix(upTo: ptr.count - 1))
                let bytes = ForeignBytes(bufferPointer: buf)
                return try! rustCall { ffi_hlogging_df33_rustbuffer_from_bytes(bytes, $0) }
            }
        }
    }

    fileprivate static func read(from buf: Reader) throws -> Self {
        let len: Int32 = try buf.readInt()
        return String(bytes: try buf.readBytes(count: Int(len)), encoding: String.Encoding.utf8)!
    }

    fileprivate func write(into buf: Writer) {
        let len = Int32(utf8.count)
        buf.writeInt(len)
        buf.writeBytes(utf8)
    }
}

// Public interface members begin here.

// Note that we don't yet support `indirect` for enums.
// See https://github.com/mozilla/uniffi-rs/issues/396 for further discussion.
public enum Metadata {
    case string(value: String)
    case array(value: [Metadata])
    case map(value: [String: Metadata])
}

extension Metadata: ViaFfiUsingByteBuffer, ViaFfi {
    fileprivate static func read(from buf: Reader) throws -> Metadata {
        let variant: Int32 = try buf.readInt()
        switch variant {
        case 1: return .string(
                value: try String.read(from: buf)
            )
        case 2: return .array(
                value: try [Metadata].read(from: buf)
            )
        case 3: return .map(
                value: try [String: Metadata].read(from: buf)
            )
        default: throw UniffiInternalError.unexpectedEnumCase
        }
    }

    fileprivate func write(into buf: Writer) {
        switch self {
        case let .string(value):
            buf.writeInt(Int32(1))
            value.write(into: buf)

        case let .array(value):
            buf.writeInt(Int32(2))
            value.write(into: buf)

        case let .map(value):
            buf.writeInt(Int32(3))
            value.write(into: buf)
        }
    }
}

extension Metadata: Equatable, Hashable {}

// Note that we don't yet support `indirect` for enums.
// See https://github.com/mozilla/uniffi-rs/issues/396 for further discussion.
public enum LoggingLevel {
    case debug
    case info
    case notice
    case warning
    case error
    case critical
}

extension LoggingLevel: ViaFfiUsingByteBuffer, ViaFfi {
    fileprivate static func read(from buf: Reader) throws -> LoggingLevel {
        let variant: Int32 = try buf.readInt()
        switch variant {
        case 1: return .debug
        case 2: return .info
        case 3: return .notice
        case 4: return .warning
        case 5: return .error
        case 6: return .critical
        default: throw UniffiInternalError.unexpectedEnumCase
        }
    }

    fileprivate func write(into buf: Writer) {
        switch self {
        case .debug:
            buf.writeInt(Int32(1))

        case .info:
            buf.writeInt(Int32(2))

        case .notice:
            buf.writeInt(Int32(3))

        case .warning:
            buf.writeInt(Int32(4))

        case .error:
            buf.writeInt(Int32(5))

        case .critical:
            buf.writeInt(Int32(6))
        }
    }
}

extension LoggingLevel: Equatable, Hashable {}

// Note that we don't yet support `indirect` for enums.
// See https://github.com/mozilla/uniffi-rs/issues/396 for further discussion.
public enum HLoggingType {
    case stdStream
    case fileLogger(directory: String)
}

extension HLoggingType: ViaFfiUsingByteBuffer, ViaFfi {
    fileprivate static func read(from buf: Reader) throws -> HLoggingType {
        let variant: Int32 = try buf.readInt()
        switch variant {
        case 1: return .stdStream
        case 2: return .fileLogger(
                directory: try String.read(from: buf)
            )
        default: throw UniffiInternalError.unexpectedEnumCase
        }
    }

    fileprivate func write(into buf: Writer) {
        switch self {
        case .stdStream:
            buf.writeInt(Int32(1))

        case let .fileLogger(directory):
            buf.writeInt(Int32(2))
            directory.write(into: buf)
        }
    }
}

extension HLoggingType: Equatable, Hashable {}
// An error type for FFI errors. These errors occur at the UniFFI level, not
// the library level.
private enum UniffiInternalError: LocalizedError {
    case bufferOverflow
    case incompleteData
    case unexpectedOptionalTag
    case unexpectedEnumCase
    case unexpectedNullPointer
    case unexpectedRustCallStatusCode
    case unexpectedRustCallError
    case rustPanic(_ message: String)

    public var errorDescription: String? {
        switch self {
        case .bufferOverflow: return "Reading the requested value would read past the end of the buffer"
        case .incompleteData: return "The buffer still has data after lifting its containing value"
        case .unexpectedOptionalTag: return "Unexpected optional tag; should be 0 or 1"
        case .unexpectedEnumCase: return "Raw enum value doesn't match any cases"
        case .unexpectedNullPointer: return "Raw pointer value was null"
        case .unexpectedRustCallStatusCode: return "Unexpected RustCallStatus code"
        case .unexpectedRustCallError: return "CALL_ERROR but no errorClass specified"
        case let .rustPanic(message): return message
        }
    }
}

private let CALL_SUCCESS: Int8 = 0
private let CALL_ERROR: Int8 = 1
private let CALL_PANIC: Int8 = 2

private extension RustCallStatus {
    init() {
        self.init(
            code: CALL_SUCCESS,
            errorBuf: RustBuffer(
                capacity: 0,
                len: 0,
                data: nil
            )
        )
    }
}

public enum WriteFileError {
    // Simple error enums only carry a message
    case FileError(message: String)

    // Simple error enums only carry a message
    case WriteError(message: String)
}

extension WriteFileError: ViaFfiUsingByteBuffer, ViaFfi {
    fileprivate static func read(from buf: Reader) throws -> WriteFileError {
        let variant: Int32 = try buf.readInt()
        switch variant {
        case 1: return .FileError(
                message: try String.read(from: buf)
            )

        case 2: return .WriteError(
                message: try String.read(from: buf)
            )

        default: throw UniffiInternalError.unexpectedEnumCase
        }
    }

    fileprivate func write(into buf: Writer) {
        switch self {
        case let .FileError(message):
            buf.writeInt(Int32(1))
            message.write(into: buf)
        case let .WriteError(message):
            buf.writeInt(Int32(2))
            message.write(into: buf)
        }
    }
}

extension WriteFileError: Equatable, Hashable {}

extension WriteFileError: Error {}

private func rustCall<T>(_ callback: (UnsafeMutablePointer<RustCallStatus>) -> T) throws -> T {
    try makeRustCall(callback, errorHandler: {
        $0.deallocate()
        return UniffiInternalError.unexpectedRustCallError
    })
}

private func rustCallWithError<T, E: ViaFfiUsingByteBuffer & Error>(_: E.Type, _ callback: (UnsafeMutablePointer<RustCallStatus>) -> T) throws -> T {
    try makeRustCall(callback, errorHandler: { try E.lift($0) })
}

private func makeRustCall<T>(_ callback: (UnsafeMutablePointer<RustCallStatus>) -> T, errorHandler: (RustBuffer) throws -> Error) throws -> T {
    var callStatus = RustCallStatus()
    let returnedVal = callback(&callStatus)
    switch callStatus.code {
    case CALL_SUCCESS:
        return returnedVal

    case CALL_ERROR:
        throw try errorHandler(callStatus.errorBuf)

    case CALL_PANIC:
        // When the rust code sees a panic, it tries to construct a RustBuffer
        // with the message.  But if that code panics, then it just sends back
        // an empty buffer.
        if callStatus.errorBuf.len > 0 {
            throw UniffiInternalError.rustPanic(try String.lift(callStatus.errorBuf))
        } else {
            callStatus.errorBuf.deallocate()
            throw UniffiInternalError.rustPanic("Rust panic")
        }

    default:
        throw UniffiInternalError.unexpectedRustCallStatusCode
    }
}

public func writeFile(filename: String, message: String) throws {
    try

        rustCallWithError(WriteFileError.self) {
            hlogging_df33_write_file(filename.lower(), message.lower(), $0)
        }
}

public func configure(label: String, level: LoggingLevel, loggerType: HLoggingType) {
    try!

        rustCall {
            hlogging_df33_configure(label.lower(), level.lower(), loggerType.lower(), $0)
        }
}

public func debug(metadata: Metadata, message: String, source: String?) {
    try!

        rustCall {
            hlogging_df33_debug(metadata.lower(), message.lower(), source.lower(), $0)
        }
}

public func info(metadata: Metadata, message: String, source: String?) {
    try!

        rustCall {
            hlogging_df33_info(metadata.lower(), message.lower(), source.lower(), $0)
        }
}

public func notice(metadata: Metadata, message: String, source: String?) {
    try!

        rustCall {
            hlogging_df33_notice(metadata.lower(), message.lower(), source.lower(), $0)
        }
}

public func warring(metadata: Metadata, message: String, source: String?) {
    try!

        rustCall {
            hlogging_df33_warring(metadata.lower(), message.lower(), source.lower(), $0)
        }
}

public func error(metadata: Metadata, message: String, source: String?) {
    try!

        rustCall {
            hlogging_df33_error(metadata.lower(), message.lower(), source.lower(), $0)
        }
}

public func critical(metadata: Metadata, message: String, source: String?) {
    try!

        rustCall {
            hlogging_df33_critical(metadata.lower(), message.lower(), source.lower(), $0)
        }
}
