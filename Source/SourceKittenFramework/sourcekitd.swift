//
//  sourcekitd.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-03.
//  Copyright (c) 2014 Realm. All rights reserved.
//

import sourcekitd

final class SourceKit {

    static let shared = SourceKit()

    init() {
        sourcekitd_initialize()
    }

    deinit {
        sourcekitd_shutdown()
    }

    // MARK: - Utility

    private func describe<T>(value: T, takeOwnership owning: Bool = true, @noescape using function: T -> UnsafeMutablePointer<Int8>) -> String! {
        let buffer = function(value)
        guard buffer != nil else { return nil }
        let length = Int(strlen(buffer))
        if let string = String(bytesNoCopy: buffer, length: length, encoding: NSUTF8StringEncoding, freeWhenDone: owning) {
            return string
        } else if owning {
            buffer.destroy()
        }
        return nil
    }

    private func describe<T>(value: T, @noescape getBuffer: T -> UnsafePointer<Int8>, @noescape getLength: T -> Int) -> String! {
        let pointer = getBuffer(value)
        guard pointer != nil else { return nil }
        let length = getLength(value)
        return String(bytesNoCopy: UnsafeMutablePointer(pointer), length: length, encoding: NSUTF8StringEncoding, freeWhenDone: false)
    }

    // MARK: -

    func setInterruptedConnectionHandler(handler: sourcekitd_interrupted_connection_handler_t) {
        sourcekitd_set_interrupted_connection_handler(handler)
    }

    // MARK: - UIDs

    func createUID(buffer: UnsafeBufferPointer<UInt8>) -> UID {
        return UID(sourcekitd_uid_get_from_buf(UnsafePointer(buffer.baseAddress), buffer.count))
    }

    // MARK: - Request API

    enum Request {
        case Dictionary([SourceKittenFramework.UID: Request])
        case Array([Request])
        case String(Swift.String)
        case Int(Swift.Int64)
        case UID(SourceKittenFramework.UID)
    }

    private func requestToUnmanaged(value: Request) -> sourcekitd_object_t {
        switch value {
        case let .Dictionary(dictionary):
            let object = sourcekitd_request_dictionary_create(nil, nil, 0)
            for (uid, value) in dictionary {
                withUnmanagedRequest(value) {
                    sourcekitd_request_dictionary_set_value(object, uid.value, $0)
                }
            }
            return object
        case let .Array(array):
            let contents = array.map(requestToUnmanaged)
            defer { contents.forEach(sourcekitd_request_release) }
            return sourcekitd_request_array_create(contents, contents.count)
        case let .Int(int):
            return sourcekitd_request_int64_create(int)
        case let .String(string):
            return string.withCString(sourcekitd_request_string_create)
        case let .UID(uid):
            return sourcekitd_request_uid_create(uid.value)
        }
    }

    func withUnmanagedRequest<Return>(value: Request, @noescape body: sourcekitd_object_t throws -> Return) rethrows -> Return {
        let object = requestToUnmanaged(value)
        defer { sourcekitd_request_release(object) }
        return try body(object)
    }

    func sendRequest(request: Request) throws -> SourceKittenFramework.Response {
        return try withUnmanagedRequest(request) {
            let response = sourcekitd_send_request_sync($0)
            let obj = Response(response)
            return try SourceKittenFramework.Response(obj)
        }
    }

    @available(*, deprecated)
    func sendRequest(request: Request) -> xpc_object_t? {
        return withUnmanagedRequest(request) {
            let response = sourcekitd_send_request_sync($0)
            return unsafeBitCast(response, Optional<xpc_object_t>.self)
        }
    }

    // MARK: - Response API

    final class Response {

        private let value: sourcekitd_response_t

        private init(_ value: sourcekitd_response_t) {
            self.value = value
        }

        deinit {
            sourcekitd_response_dispose(value)
        }

    }

    struct Variant {

        private let value: sourcekitd_variant_t
        private let owner: Response

        private init(_ value: sourcekitd_variant_t, within owner: Response) {
            self.value = value
            self.owner = owner
        }

    }

}

extension UID: CustomStringConvertible, CustomDebugStringConvertible {

    private var stringValue: String {
        return SourceKit.shared.describe(value, getBuffer: sourcekitd_uid_get_string_ptr, getLength: sourcekitd_uid_get_length)
    }

    /// A textual representation of `self`.
    public var description: String {
        return stringValue
    }

    /// A textual representation of `self`, suitable for debugging.
    public var debugDescription: String {
        return stringValue.debugDescription
    }
    
}

extension SourceKit.Request: CustomDebugStringConvertible {

    init<Key: RawRepresentable where Key.RawValue == SourceKittenFramework.UID>(_ literal: DictionaryLiteral<Key, SourceKit.Request>) {
        var dictionary = Swift.Dictionary<SourceKittenFramework.UID, SourceKit.Request>(minimumCapacity: literal.count)
        for (key, value) in literal {
            dictionary[key.rawValue] = value
        }
        self = .Dictionary(dictionary)
    }

    init<Sequence: SequenceType where Sequence.Generator.Element == SourceKit.Request>(_ sequence: Sequence) {
        self = .Array(Swift.Array(sequence))
    }

    init<UID: RawRepresentable where UID.RawValue == SourceKittenFramework.UID>(_ value: UID) {
        self = .UID(value.rawValue)
    }

    init(_ value: SourceKittenFramework.UID) {
        self = .UID(value)
    }

    init(_ string: Swift.String) {
        self = .String(string)
    }

    init<Int: SignedIntegerType>(_ int: Int) {
        self = .Int(numericCast(int))
    }

    var debugDescription: Swift.String {
        return SourceKit.shared.withUnmanagedRequest(self) {
            SourceKit.shared.describe($0, using: sourcekitd_request_description_copy)
        }
    }

}

extension SourceKit.Response {

    var isError: Bool {
        return sourcekitd_response_is_error(value)
    }

    var errorValue: sourcekitd_error_t {
        return sourcekitd_response_error_get_kind(value)
    }

    var errorDescription: String! {
        assert(isError)
        return SourceKit.shared.describe(value, takeOwnership: false) {
            UnsafeMutablePointer(sourcekitd_response_error_get_description($0))
        }
    }

    var variant: SourceKit.Variant {
        return SourceKit.Variant(sourcekitd_response_get_value(value), within: self)
    }

    var valueDescription: String! {
        assert(!isError)
        return SourceKit.shared.describe(value, using: sourcekitd_response_description_copy)
    }
    
}

extension SourceKit.Variant: CustomStringConvertible, CustomDebugStringConvertible {

    var description: String {
        return SourceKit.shared.describe(value, using: sourcekitd_variant_description_copy)
    }

    var debugDescription: String {
        return description.debugDescription
    }

    var kind: sourcekitd_variant_type_t {
        return sourcekitd_variant_get_type(value)
    }

    subscript (key: UID) -> SourceKit.Variant? {
        let newValue = sourcekitd_variant_dictionary_get_value(value, key.value)
        guard sourcekitd_variant_get_type(newValue) != SOURCEKITD_VARIANT_TYPE_NULL else { return nil }
        return SourceKit.Variant.init(newValue, within: owner)
    }

    var arrayStart: Int {
        return 0
    }

    var arrayEnd: Int {
        return sourcekitd_variant_array_get_count(value)
    }

    subscript (position: Swift.Int) -> SourceKit.Variant {
        let newValue = sourcekitd_variant_array_get_value(value, position)
        return SourceKit.Variant.init(newValue, within: owner)
    }

    var intValue: Int64 {
        return sourcekitd_variant_int64_get_value(value)
    }

    var boolValue: Bool {
        return sourcekitd_variant_bool_get_value(value)
    }

    var stringValue: String! {
        return SourceKit.shared.describe(value, getBuffer: sourcekitd_variant_string_get_ptr, getLength: sourcekitd_variant_string_get_length)
    }

    var uidValue: UID {
        return UID(sourcekitd_variant_uid_get_value(value))
    }

}
