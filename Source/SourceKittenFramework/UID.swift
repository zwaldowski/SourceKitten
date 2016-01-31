//
//  UID.swift
//  SourceKitten
//
//  Created by Zachary Waldowski on 1/17/16.
//  Copyright © 2016 SourceKitten. All rights reserved.
//

#if SWIFT_PACKAGE
import sourcekitd
#endif

public struct UID {

    private let value: sourcekitd_uid_t

    init(_ value: sourcekitd_uid_t) {
        self.value = value
    }

}

extension SourceKittenFramework.UID: StringLiteralConvertible, Hashable {

    private init(_ staticString: StaticString) {
        value = staticString.withUTF8Buffer {
            sourcekitd_uid_get_from_buf(.init($0.baseAddress), $0.count)
        }
    }

    /// Create an instance initialized to `value`.
    public init(stringLiteral value: StaticString) {
        self.init(value)
    }

    /// Create an instance initialized to `value`.
    public init(unicodeScalarLiteral value: StaticString) {
        self.init(value)
    }

    /// Create an instance initialized to `value`.
    public init(extendedGraphemeClusterLiteral value: StaticString) {
        self.init(value)
    }

    /// The hash value.
    ///
    /// - Note: The hash value is not guaranteed to be stable across
    ///   different invocations of the same program.  Do not persist the
    ///   hash value across program runs.
    public var hashValue: Int {
        return value.hashValue
    }
}

extension UID: CustomStringConvertible, CustomDebugStringConvertible {

    private func describe<T>(value: T, @noescape getBuffer: T -> UnsafePointer<Int8>, @noescape getLength: T -> Int) -> String! {
        let pointer = getBuffer(value)
        guard pointer != nil else { return nil }
        let length = getLength(value)
        return String(bytesNoCopy: UnsafeMutablePointer(pointer), length: length, encoding: NSUTF8StringEncoding, freeWhenDone: false)
    }

    private var stringValue: String {
        return describe(value, getBuffer: sourcekitd_uid_get_string_ptr, getLength: sourcekitd_uid_get_length)
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

/**
 Returns true if `lhs` UID is equal to `rhs` UID.

 - parameter lhs: UID to compare to `rhs`.
 - parameter rhs: UID to compare to `lhs`.

 - returns: True if `lhs` UID is equal to `rhs` UID.
 */
public func ==(lhs: UID, rhs: UID) -> Bool {
    return lhs.value == rhs.value
}

// MARK: - Deprecated

extension UID {

    @available(*, deprecated)
    init?(bitPattern value: UInt64) {
        // UID's are always higher than UInt32.max
        guard value >= UInt64(UInt32.max) else { return nil }
        self.value = .init(bitPattern: UInt(value))
    }

}

extension RawRepresentable where RawValue == UID {

    @available(*, deprecated)
    init?(bitPattern value: UInt64) {
        guard let uid = RawValue(bitPattern: value) else { return nil }
        self.init(rawValue: uid)
    }
    
}
