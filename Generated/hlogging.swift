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
            RustBuffer.from(ptr)
        }
        self.init(capacity: rbuf.capacity, len: rbuf.len, data: rbuf.data)
    }

    static func from(_ ptr: UnsafeBufferPointer<UInt8>) -> RustBuffer {
        try! rustCall { ffi_hlogging_ab46_rustbuffer_from_bytes(ForeignBytes(bufferPointer: ptr), $0) }
    }

    // Frees the buffer in place.
    // The buffer must not be used after this is called.
    func deallocate() {
        try! rustCall { ffi_hlogging_ab46_rustbuffer_free(self, $0) }
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

    static func lift(_ buf: FfiType) throws -> Self {
        let reader = Reader(data: Data(rustBuffer: buf))
        let value = try Self.read(from: reader)
        if reader.hasRemaining() {
            throw UniffiInternalError.incompleteData
        }
        buf.deallocate()
        return value
    }

    func lower() -> FfiType {
        let writer = Writer()
        write(into: writer)
        return RustBuffer(bytes: writer.bytes)
    }
}

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
    case unexpectedStaleHandle
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
        case .unexpectedStaleHandle: return "The object in the handle map has been dropped already"
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

// Protocols for converters we'll implement in templates

private protocol FfiConverter {
    associatedtype SwiftType
    associatedtype FfiType

    static func lift(_ ffiValue: FfiType) throws -> SwiftType
    static func lower(_ value: SwiftType) -> FfiType

    static func read(from: Reader) throws -> SwiftType
    static func write(_ value: SwiftType, into: Writer)
}

private protocol FfiConverterUsingByteBuffer: FfiConverter where FfiType == RustBuffer {
    // Empty, because we want to declare some helper methods in the extension below.
}

extension FfiConverterUsingByteBuffer {
    static func lower(_ value: SwiftType) -> FfiType {
        let writer = Writer()
        Self.write(value, into: writer)
        return RustBuffer(bytes: writer.bytes)
    }

    static func lift(_ buf: FfiType) throws -> SwiftType {
        let reader = Reader(data: Data(rustBuffer: buf))
        let value = try Self.read(from: reader)
        if reader.hasRemaining() {
            throw UniffiInternalError.incompleteData
        }
        buf.deallocate()
        return value
    }
}

// Helpers for structural types. Note that because of canonical_names, it /should/ be impossible
// to make another `FfiConverterSequence` etc just using the UDL.
private enum FfiConverterSequence {
    static func write<T>(_ value: [T], into buf: Writer, writeItem: (T, Writer) -> Void) {
        let len = Int32(value.count)
        buf.writeInt(len)
        for item in value {
            writeItem(item, buf)
        }
    }

    static func read<T>(from buf: Reader, readItem: (Reader) throws -> T) throws -> [T] {
        let len: Int32 = try buf.readInt()
        var seq = [T]()
        seq.reserveCapacity(Int(len))
        for _ in 0 ..< len {
            seq.append(try readItem(buf))
        }
        return seq
    }
}

private enum FfiConverterOptional {
    static func write<T>(_ value: T?, into buf: Writer, writeItem: (T, Writer) -> Void) {
        guard let value = value else {
            buf.writeInt(Int8(0))
            return
        }
        buf.writeInt(Int8(1))
        writeItem(value, buf)
    }

    static func read<T>(from buf: Reader, readItem: (Reader) throws -> T) throws -> T? {
        switch try buf.readInt() as Int8 {
        case 0: return nil
        case 1: return try readItem(buf)
        default: throw UniffiInternalError.unexpectedOptionalTag
        }
    }
}

private enum FfiConverterDictionary {
    static func write<T>(_ value: [String: T], into buf: Writer, writeItem: (String, T, Writer) -> Void) {
        let len = Int32(value.count)
        buf.writeInt(len)
        for (key, value) in value {
            writeItem(key, value, buf)
        }
    }

    static func read<T>(from buf: Reader, readItem: (Reader) throws -> (String, T)) throws -> [String: T] {
        let len: Int32 = try buf.readInt()
        var dict = [String: T]()
        dict.reserveCapacity(Int(len))
        for _ in 0 ..< len {
            let (key, value) = try readItem(buf)
            dict[key] = value
        }
        return dict
    }
}

// Public interface members begin here.

private extension NSLock {
    func withLock<T>(f: () throws -> T) rethrows -> T {
        lock()
        defer { self.unlock() }
        return try f()
    }
}

private typealias Handle = UInt64
private class ConcurrentHandleMap<T> {
    private var leftMap: [Handle: T] = [:]
    private var counter: [Handle: UInt64] = [:]
    private var rightMap: [ObjectIdentifier: Handle] = [:]

    private let lock = NSLock()
    private var currentHandle: Handle = 0
    private let stride: Handle = 1

    func insert(obj: T) -> Handle {
        lock.withLock {
            let id = ObjectIdentifier(obj as AnyObject)
            let handle = rightMap[id] ?? {
                currentHandle += stride
                let handle = currentHandle
                leftMap[handle] = obj
                rightMap[id] = handle
                return handle
            }()
            counter[handle] = (counter[handle] ?? 0) + 1
            return handle
        }
    }

    func get(handle: Handle) -> T? {
        lock.withLock {
            leftMap[handle]
        }
    }

    func delete(handle: Handle) {
        remove(handle: handle)
    }

    @discardableResult
    func remove(handle: Handle) -> T? {
        lock.withLock {
            defer { counter[handle] = (counter[handle] ?? 1) - 1 }
            guard counter[handle] == 1 else { return leftMap[handle] }
            let obj = leftMap.removeValue(forKey: handle)
            if let obj = obj {
                rightMap.removeValue(forKey: ObjectIdentifier(obj as AnyObject))
            }
            return obj
        }
    }
}

// Magic number for the Rust proxy to call using the same mechanism as every other method,
// to free the callback once it's dropped by Rust.
private let IDX_CALLBACK_FREE: Int32 = 0

private class FfiConverterCallbackInterface<CallbackInterface> {
    fileprivate let handleMap = ConcurrentHandleMap<CallbackInterface>()

    func drop(handle: Handle) {
        handleMap.remove(handle: handle)
    }

    func lift(_ handle: Handle) throws -> CallbackInterface {
        guard let callback = handleMap.get(handle: handle) else {
            throw UniffiInternalError.unexpectedStaleHandle
        }
        return callback
    }

    func read(from buf: Reader) throws -> CallbackInterface {
        let handle: Handle = try buf.readInt()
        return try lift(handle)
    }

    func lower(_ v: CallbackInterface) -> Handle {
        let handle = handleMap.insert(obj: v)
        return handle
        // assert(handleMap.get(handle: obj) == v, "Handle map is not returning the object we just placed there. This is a bug in the HandleMap.")
    }

    func write(_ v: CallbackInterface, into buf: Writer) {
        buf.writeInt(lower(v))
    }
}

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
                value: try FfiConverterSequenceEnumMetadata.read(from: buf)
            )
        case 3: return .map(
                value: try FfiConverterDictionaryEnumMetadata.read(from: buf)
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
            FfiConverterSequenceEnumMetadata.write(value, into: buf)

        case let .map(value):
            buf.writeInt(Int32(3))
            FfiConverterDictionaryEnumMetadata.write(value, into: buf)
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
    case mmapLogger(directory: String)
}

extension HLoggingType: ViaFfiUsingByteBuffer, ViaFfi {
    fileprivate static func read(from buf: Reader) throws -> HLoggingType {
        let variant: Int32 = try buf.readInt()
        switch variant {
        case 1: return .stdStream
        case 2: return .fileLogger(
                directory: try String.read(from: buf)
            )
        case 3: return .mmapLogger(
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

        case let .mmapLogger(directory):
            buf.writeInt(Int32(3))
            directory.write(into: buf)
        }
    }
}

extension HLoggingType: Equatable, Hashable {}

public func writeFile(filename: String, message: String) throws {
    try

        rustCallWithError(WriteFileError.self) {
            hlogging_ab46_write_file(filename.lower(), message.lower(), $0)
        }
}

public func configure(label: String, level: LoggingLevel, loggerType: HLoggingType) {
    try!

        rustCall {
            hlogging_ab46_configure(label.lower(), level.lower(), loggerType.lower(), $0)
        }
}

public func debug(metadata: Metadata, message: String, source: String?) {
    try!

        rustCall {
            hlogging_ab46_debug(metadata.lower(), message.lower(), FfiConverterOptionString.lower(source), $0)
        }
}

public func info(metadata: Metadata, message: String, source: String?) {
    try!

        rustCall {
            hlogging_ab46_info(metadata.lower(), message.lower(), FfiConverterOptionString.lower(source), $0)
        }
}

public func notice(metadata: Metadata, message: String, source: String?) {
    try!

        rustCall {
            hlogging_ab46_notice(metadata.lower(), message.lower(), FfiConverterOptionString.lower(source), $0)
        }
}

public func warring(metadata: Metadata, message: String, source: String?) {
    try!

        rustCall {
            hlogging_ab46_warring(metadata.lower(), message.lower(), FfiConverterOptionString.lower(source), $0)
        }
}

public func error(metadata: Metadata, message: String, source: String?) {
    try!

        rustCall {
            hlogging_ab46_error(metadata.lower(), message.lower(), FfiConverterOptionString.lower(source), $0)
        }
}

public func critical(metadata: Metadata, message: String, source: String?) {
    try!

        rustCall {
            hlogging_ab46_critical(metadata.lower(), message.lower(), FfiConverterOptionString.lower(source), $0)
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

// Declaration and FfiConverters for FilterPlugin Callback Interface

public protocol FilterPlugin: AnyObject {
    func filter(metadata: Metadata, message: String) -> Bool
}

// The ForeignCallback that is passed to Rust.
private let foreignCallbackCallbackInterfaceFilterPlugin: ForeignCallback =
    { (handle: Handle, method: Int32, args: RustBuffer) -> RustBuffer in
        func invokeFilter(_ swiftCallbackInterface: FilterPlugin, _ args: RustBuffer) throws -> RustBuffer {
            defer { args.deallocate() }

            let reader = Reader(data: Data(rustBuffer: args))
            let result = swiftCallbackInterface.filter(
                metadata: try Metadata.read(from: reader),
                message: try String.read(from: reader)
            )
            let writer = Writer()
            result.write(into: writer)
            return RustBuffer(bytes: writer.bytes)
            // TODO: catch errors and report them back to Rust.
            // https://github.com/mozilla/uniffi-rs/issues/351
        }

        let cb = try! ffiConverterCallbackInterfaceFilterPlugin.lift(handle)
        switch method {
        case IDX_CALLBACK_FREE:
            ffiConverterCallbackInterfaceFilterPlugin.drop(handle: handle)
            return RustBuffer()
        case 1: return try! invokeFilter(cb, args)

        // This should never happen, because an out of bounds method index won't
        // ever be used. Once we can catch errors, we should return an InternalError.
        // https://github.com/mozilla/uniffi-rs/issues/351
        default: return RustBuffer()
        }
    }

// The ffiConverter which transforms the Callbacks in to Handles to pass to Rust.
private let ffiConverterCallbackInterfaceFilterPlugin: FfiConverterCallbackInterface<FilterPlugin> = {
    try! rustCall { (err: UnsafeMutablePointer<RustCallStatus>) in
        ffi_hlogging_ab46_FilterPlugin_init_callback(foreignCallbackCallbackInterfaceFilterPlugin, err)
    }
    return FfiConverterCallbackInterface<FilterPlugin>()
}()

// Declaration and FfiConverters for HandlerPlugin Callback Interface

public protocol HandlerPlugin: AnyObject {
    func handle(metadata: Metadata, message: String) -> String
}

// The ForeignCallback that is passed to Rust.
private let foreignCallbackCallbackInterfaceHandlerPlugin: ForeignCallback =
    { (handle: Handle, method: Int32, args: RustBuffer) -> RustBuffer in
        func invokeHandle(_ swiftCallbackInterface: HandlerPlugin, _ args: RustBuffer) throws -> RustBuffer {
            defer { args.deallocate() }

            let reader = Reader(data: Data(rustBuffer: args))
            let result = swiftCallbackInterface.handle(
                metadata: try Metadata.read(from: reader),
                message: try String.read(from: reader)
            )
            let writer = Writer()
            result.write(into: writer)
            return RustBuffer(bytes: writer.bytes)
            // TODO: catch errors and report them back to Rust.
            // https://github.com/mozilla/uniffi-rs/issues/351
        }

        let cb = try! ffiConverterCallbackInterfaceHandlerPlugin.lift(handle)
        switch method {
        case IDX_CALLBACK_FREE:
            ffiConverterCallbackInterfaceHandlerPlugin.drop(handle: handle)
            return RustBuffer()
        case 1: return try! invokeHandle(cb, args)

        // This should never happen, because an out of bounds method index won't
        // ever be used. Once we can catch errors, we should return an InternalError.
        // https://github.com/mozilla/uniffi-rs/issues/351
        default: return RustBuffer()
        }
    }

// The ffiConverter which transforms the Callbacks in to Handles to pass to Rust.
private let ffiConverterCallbackInterfaceHandlerPlugin: FfiConverterCallbackInterface<HandlerPlugin> = {
    try! rustCall { (err: UnsafeMutablePointer<RustCallStatus>) in
        ffi_hlogging_ab46_HandlerPlugin_init_callback(foreignCallbackCallbackInterfaceHandlerPlugin, err)
    }
    return FfiConverterCallbackInterface<HandlerPlugin>()
}()

extension Bool: ViaFfi {
    fileprivate typealias FfiType = Int8

    fileprivate static func read(from buf: Reader) throws -> Self {
        return try lift(buf.readInt())
    }

    fileprivate func write(into buf: Writer) {
        buf.writeInt(lower())
    }

    fileprivate static func lift(_ v: FfiType) throws -> Self {
        return v != 0
    }

    fileprivate func lower() -> FfiType {
        return self ? 1 : 0
    }
}

extension String: ViaFfi {
    fileprivate typealias FfiType = RustBuffer

    fileprivate static func lift(_ v: FfiType) throws -> Self {
        defer {
            v.deallocate()
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
                return RustBuffer.from(buf)
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

// Helper code for HLoggingType enum is found in EnumTemplate.swift
// Helper code for LoggingLevel enum is found in EnumTemplate.swift
// Helper code for Metadata enum is found in EnumTemplate.swift
// Helper code for WriteFileError error is found in ErrorTemplate.swift

private enum FfiConverterOptionString: FfiConverterUsingByteBuffer {
    typealias SwiftType = String?

    static func write(_ value: SwiftType, into buf: Writer) {
        FfiConverterOptional.write(value, into: buf) { item, buf in
            item.write(into: buf)
        }
    }

    static func read(from buf: Reader) throws -> SwiftType {
        try FfiConverterOptional.read(from: buf) { buf in
            try String.read(from: buf)
        }
    }
}

private enum FfiConverterSequenceEnumMetadata: FfiConverterUsingByteBuffer {
    typealias SwiftType = [Metadata]

    static func write(_ value: SwiftType, into buf: Writer) {
        FfiConverterSequence.write(value, into: buf) { item, buf in
            item.write(into: buf)
        }
    }

    static func read(from buf: Reader) throws -> SwiftType {
        try FfiConverterSequence.read(from: buf) { buf in
            try Metadata.read(from: buf)
        }
    }
}

private enum FfiConverterDictionaryEnumMetadata: FfiConverterUsingByteBuffer {
    typealias SwiftType = [String: Metadata]

    static func write(_ value: SwiftType, into buf: Writer) {
        FfiConverterDictionary.write(value, into: buf) { key, value, buf in
            key.write(into: buf)
            value.write(into: buf)
        }
    }

    static func read(from buf: Reader) throws -> SwiftType {
        try FfiConverterDictionary.read(from: buf) { buf in
            (try String.read(from: buf),
             try Metadata.read(from: buf))
        }
    }
}

/**
 * Top level initializers and tear down methods.
 *
 * This is generated by uniffi.
 */
public enum HloggingLifecycle {
    /**
     * Initialize the FFI and Rust library. This should be only called once per application.
     */
    func initialize() {
        // No initialization code needed
    }
}
