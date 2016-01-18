//
//  UID.swift
//  SourceKitten
//
//  Created by Zachary Waldowski on 1/17/16.
//  Copyright © 2016 SourceKitten. All rights reserved.
//

import sourcekitd

public struct UID {

    let value: sourcekitd_uid_t

    init(_ value: sourcekitd_uid_t) {
        self.value = value
    }

}

extension SourceKittenFramework.UID: StringLiteralConvertible, Hashable {

    private init(_ staticString: StaticString) {
        self = staticString.withUTF8Buffer(SourceKit.shared.createUID)
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
