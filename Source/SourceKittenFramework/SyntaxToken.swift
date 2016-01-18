//
//  SyntaxToken.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-03.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

/// Represents a single Swift syntax token.
public struct SyntaxToken {

    /// Token type. See SyntaxKind.
    public let kind: SyntaxKind
    @available(*, unavailable)
    public var typeNew: SyntaxKind {
        return kind
    }
    @available(*, unavailable)
    public var type: String {
        return String(kind.rawValue)
    }
    /// Token offset.
    public let offset: Int
    /// Token length.
    public let length: Int

    /// Dictionary representation of SyntaxToken. Useful for NSJSONSerialization.
    public var dictionaryValue: [String: AnyObject] {
        return ["type": String(kind.rawValue), "offset": offset, "length": length]
    }

    /**
    Create a SyntaxToken by directly passing in its property values.

    - parameter type:   Token type. See SyntaxKind.
    - parameter offset: Token offset.
    - parameter length: Token length.
    */
    public init(kind: SyntaxKind, offset: Int, length: Int) {
        self.kind = kind
        self.offset = offset
        self.length = length
    }
}

extension SyntaxToken: SourceKitResponseConvertible {

    public init(sourceKitResponse response: Response) throws {
        let dict = try response.value(of: Response.Dictionary.self)
        self.kind = try dict.uidFor(SwiftDocKey.Kind, of: SyntaxKind.self)
        self.offset = (try? numericCast(dict.valueFor(SwiftDocKey.Offset, of: Int64.self))) ?? 0
        self.length = (try? numericCast(dict.valueFor(SwiftDocKey.Length, of: Int64.self))) ?? 0
    }

}

// MARK: Equatable

extension SyntaxToken: Equatable {}

/**
Returns true if `lhs` SyntaxToken is equal to `rhs` SyntaxToken.

- parameter lhs: SyntaxToken to compare to `rhs`.
- parameter rhs: SyntaxToken to compare to `lhs`.

- returns: True if `lhs` SyntaxToken is equal to `rhs` SyntaxToken.
*/
public func ==(lhs: SyntaxToken, rhs: SyntaxToken) -> Bool {
    return (lhs.kind == rhs.kind) && (lhs.offset == rhs.offset) && (lhs.length == rhs.length)
}

// MARK: CustomStringConvertible

extension SyntaxToken: CustomStringConvertible {
    /// A textual JSON representation of `SyntaxToken`.
    public var description: String { return toJSON(dictionaryValue) }
}
