//
//  Response.swift
//  SourceKitten
//
//  Created by Zachary Waldowski on 1/17/16.
//  Copyright © 2016 SourceKitten. All rights reserved.
//

import sourcekitd

public struct Response {

    public struct Error: ErrorType {
        private enum Storage {
            case Native(SourceKit.Response)
            case Raw(sourcekitd_error_t)
        }

        private let storage: Storage

        private init(_ obj: SourceKit.Response) {
            self.storage = .Native(obj)
        }

        private init(_ value: sourcekitd_error_t) {
            self.storage = .Raw(value)
        }
    }

    private enum Storage {
        case Root(SourceKit.Response)
        case Child(SourceKit.Variant)
    }

    private let storage: Storage

    init(_ variant: SourceKit.Response) throws {
        guard !variant.isError else {
            throw Error(variant)
        }
        self.storage = .Root(variant)
    }

    private init(_ variant: SourceKit.Variant) {
        self.storage = .Child(variant)
    }

    public struct Array: CollectionType {
        private let value: SourceKit.Variant
        private init(_ value: SourceKit.Variant) {
            self.value = value
        }

        public var startIndex: Int {
            return value.arrayStart
        }

        public var endIndex: Int {
            return value.arrayEnd
        }

        /// Returns the element at the given `position`.
        public subscript (position: Int) -> Response {
            guard case indices = position else {
                preconditionFailure("Array index out of bounds")
            }
            return Response(value[position])
        }
    }

    public struct Dictionary {
        private let value: SourceKit.Variant
        private init(_ value: SourceKit.Variant) {
            self.value = value
        }

        public subscript (key: SourceKittenFramework.UID) -> Response? {
            return value[key].map(Response.init)
        }
    }

    public enum Value {
        case Dictionary(Response.Dictionary)
        case Array(Response.Array)
        case Int(Swift.Int64)
        case String(Swift.String)
        case UID(SourceKittenFramework.UID)
        case Bool(Swift.Bool)
    }

    public var value: Value {
        let variant: SourceKit.Variant
        switch storage {
        case let .Root(owner):
            variant = owner.variant
        case let .Child(theVariant):
            variant = theVariant
        }

        switch variant.kind {
        case SOURCEKITD_VARIANT_TYPE_DICTIONARY:
            return .Dictionary(.init(variant))
        case SOURCEKITD_VARIANT_TYPE_ARRAY:
            return .Array(.init(variant))
        case SOURCEKITD_VARIANT_TYPE_INT64:
            return .Int(variant.intValue)
        case SOURCEKITD_VARIANT_TYPE_STRING:
            return .String(variant.stringValue)
        case SOURCEKITD_VARIANT_TYPE_UID:
            return .UID(variant.uidValue)
        case SOURCEKITD_VARIANT_TYPE_BOOL:
            return .Bool(variant.boolValue)
        default:
            preconditionFailure("Unexpected null variant; should be Error or no-such-value in Dictionary")
        }
    }
}

func ~=(match: Response.Error, error: ErrorType) -> Bool {
    guard let sourceKitError = error as? Response.Error else { return false }
    return match.rawValue == sourceKitError.rawValue
}

extension Response.Error: RawRepresentable, CustomStringConvertible {

    static var ConnectionInterrupted: Response.Error {
        return .init(rawValue: SOURCEKITD_ERROR_CONNECTION_INTERRUPTED.rawValue)
    }

    static var RequestInvalid: Response.Error {
        return .init(rawValue: SOURCEKITD_ERROR_REQUEST_INVALID.rawValue)
    }

    static var RequestFailed: Response.Error {
        return .init(rawValue: SOURCEKITD_ERROR_REQUEST_FAILED.rawValue)
    }

    static var RequestCancelled: Response.Error {
        return .init(rawValue: SOURCEKITD_ERROR_CONNECTION_INTERRUPTED.rawValue)
    }

    public typealias RawValue = sourcekitd_error_t.RawValue

    public init(rawValue code: RawValue) {
        self.init(sourcekitd_error_t(code))
    }

    public var rawValue: RawValue {
        switch storage {
        case let .Native(owner):
            return owner.errorValue.rawValue
        case let .Raw(value):
            return value.rawValue
        }
    }

    public var description: String {
        switch storage {
        case let .Native(owner):
            return owner.errorDescription
        case .Raw:
            return "An unknown error occurred"
        }
    }

}
