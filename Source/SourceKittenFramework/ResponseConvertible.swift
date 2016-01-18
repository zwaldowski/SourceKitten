//
//  ResponseConvertible.swift
//  SourceKitten
//
//  Created by Zachary Waldowski on 1/18/16.
//  Copyright © 2016 SourceKitten. All rights reserved.
//

extension Response {

    public enum ConversionError: ErrorType {
        /// The `key` was not found in the dictionary
        case KeyNotFound(key: Swift.String)

        /// Unexpected value was found that is not convertible to `type`
        case ValueNotConvertible(type: Any.Type)
    }

}

public protocol SourceKitResponseConvertible {

    /// Creates an instance of the model with a SourceKit value.
    /// - parameter sourceKitValue: An instance of a `Response` value from
    ///             which to construct an instance of the implementing type.
    /// - throws: `Response.ConversionError`.
    init(sourceKitResponse: Response) throws

}

extension Response.Dictionary: SourceKitResponseConvertible {

    /// An initializer to create a Dictionary from a SourceKit value.
    /// - parameter value: An instance of `Response.Value`.
    /// - throws: `Response.ConversionError`.
    public init(sourceKitResponse response: Response) throws {
        guard case let .Dictionary(dictionary) = response.value else {
            throw Response.ConversionError.ValueNotConvertible(type: Response.Dictionary.self)
        }
        self = dictionary
    }

}

extension Response.Array: SourceKitResponseConvertible {

    /// An initializer to create an Array from a SourceKit value.
    /// - parameter value: An instance of `Response.Value`.
    /// - throws: `Response.ConversionError`.
    public init(sourceKitResponse response: Response) throws {
        guard case let .Array(array) = response.value else {
            throw Response.ConversionError.ValueNotConvertible(type: Response.Array.self)
        }
        self = array
    }

}

extension Int64: SourceKitResponseConvertible {

    /// An initializer to create an instance of `Int64` from a SourceKit value.
    /// - parameter value: An instance of `Response.Value`.
    /// - throws: `Response.ConversionError`.
    public init(sourceKitResponse response: Response) throws {
        guard case let .Int(int) = response.value else {
            throw Response.ConversionError.ValueNotConvertible(type: Swift.Int64.self)
        }
        self = int
    }

}

extension String: SourceKitResponseConvertible {

    /// An initializer to create an instance of `String` from a SourceKit value.
    /// - parameter value: An instance of `Response.Value`.
    /// - throws: `Response.ConversionError`.
    public init(sourceKitResponse response: Response) throws {
        guard case let .String(string) = response.value else {
            throw Response.ConversionError.ValueNotConvertible(type: Swift.String.self)
        }
        self = string
    }

}

extension UID: SourceKitResponseConvertible {

    /// An initializer to create an instance of `UID` from a SourceKit value.
    /// - parameter value: An instance of `Response.Value`.
    /// - throws: `Response.ConversionError`.
    public init(sourceKitResponse response: Response) throws {
        guard case let .UID(uid) = response.value else {
            throw Response.ConversionError.ValueNotConvertible(type: UID.self)
        }
        self = uid
    }
    
}

extension Bool {

    /// An initializer to create an instance of `Bool` from a SourceKit value.
    /// - parameter value: An instance of `Response.Value`.
    /// - throws: `Response.ConversionError`.
    public init(sourceKitResponse response: Response) throws {
        guard case let .Bool(bool) = response.value else {
            throw Response.ConversionError.ValueNotConvertible(type: Swift.Bool.self)
        }
        self = bool
    }
    
}


extension Response.Dictionary {
    /**
     Get SourceKit convertible value from dictionary.

     - parameter dictionary: Dictionary to get value from.

     - returns: Value if successful.
     */
    public func valueFor<Value: SourceKitResponseConvertible, Key: RawRepresentable where Key.RawValue == UID>(key: Key, of: Value.Type = Value.self) throws -> Value {
        let raw = key.rawValue
        guard let response = self[raw] else {
            throw Response.ConversionError.KeyNotFound(key: String(raw))
        }
        return try response.value()
    }

    /**
     Get unique keyed string from dictionary.

     - parameter dictionary: Dictionary to get value from.

     - returns: Unique ID enum case if successful.
     */
    public func uidFor<Key: RawRepresentable, Value: RawRepresentable where Key.RawValue == UID, Value.RawValue == UID>(key: Key, of _: Value.Type = Value.self) throws -> Value {
        let raw = key.rawValue
        guard let response = self[raw] else {
            throw Response.ConversionError.KeyNotFound(key: String(raw))
        }
        return try response.uid()
    }
}

extension Response {
    public func value<Value: SourceKitResponseConvertible>(of _: Value.Type = Value.self) throws -> Value {
        return try Value(sourceKitResponse: self)
    }

    public func uid<Value: RawRepresentable where Value.RawValue == UID>(of _: Value.Type = Value.self) throws -> Value {
        guard let value = try Value(rawValue: value()) else {
            throw Response.ConversionError.ValueNotConvertible(type: Value.self)
        }
        return value
    }
}