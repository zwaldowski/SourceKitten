//
//  SyntaxMap.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-03.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation
import SwiftXPC

/// Represents a Swift file's syntax information.
public struct SyntaxMap {
    /// Array of SyntaxToken's.
    public let tokens: [SyntaxToken]

    /**
    Create a SyntaxMap by passing in tokens directly.

    - parameter tokens: Array of SyntaxToken's.
    */
    public init(tokens: [SyntaxToken]) {
        self.tokens = tokens
    }

    private enum ResponseKey: UID {
        case Results        = "key.results"
        case Kind           = "key.kind"
        case Context        = "key.context"
        case Name           = "key.name"
        case Description    = "key.description"
        case SourceText     = "key.sourcetext"
        case TypeName       = "key.typename"
        case ModuleName     = "key.modulename"
        case DocBrief       = "key.doc.brief"
        case AssociatedUSRs = "key.associated_usrs"
    }

    /**
    Create a SyntaxMap by passing in NSData from a SourceKit `editor.open` response to be parsed.

    - parameter data: NSData from a SourceKit `editor.open` response
    */
    @available(*, deprecated)
    public init(data: NSData) {
        var numberOfTokens = 0
        data.getBytes(&numberOfTokens, range: NSRange(location: 8, length: 8))
        numberOfTokens = numberOfTokens >> 4

        tokens = 16.stride(through: numberOfTokens * 16, by: 16).map { parserOffset in
            var uid = UInt64(0), offset = 0, length = 0
            data.getBytes(&uid, range: NSRange(location: parserOffset, length: 8))
            data.getBytes(&offset, range: NSRange(location: 8 + parserOffset, length: 4))
            data.getBytes(&length, range: NSRange(location: 12 + parserOffset, length: 4))

            return SyntaxToken(
                kind: SyntaxKind(bitPattern: uid) ?? .Unknown,
                offset: offset,
                length: length >> 1
            )
        }
    }

    /**
    Returns the range of the last contiguous comment-like block from the tokens in `self` prior to
    `offset`.

    - parameter offset: Last possible byte offset of the range's start.
    */
    public func commentRangeBeforeOffset(offset: Int) -> Range<Int>? {

        // be lazy for performance
        let tokensBeforeOffset = tokens.lazy.reverse().filter { $0.offset < offset }

        func isDoc(token: SyntaxToken) -> Bool {
            return SyntaxKind.docComments.contains(token.kind)
        }

        func isNotDoc(token: SyntaxToken) -> Bool {
            return !isDoc(token)
        }

        guard let commentBegin = tokensBeforeOffset.indexOf(isDoc) else { return nil }
        let tokensBeginningComment = tokensBeforeOffset.suffixFrom(commentBegin)

        // For avoiding declaring `var` with type annotation before `if let`, use `map()`
        let commentEnd = tokensBeginningComment.indexOf(isNotDoc)
        let commentTokensImmediatelyPrecedingOffset = (
            commentEnd.map(tokensBeginningComment.prefixUpTo) ?? tokensBeginningComment
        ).reverse()

        return commentTokensImmediatelyPrecedingOffset.first.flatMap { firstToken in
            return commentTokensImmediatelyPrecedingOffset.last.map { lastToken in
                return Range(start: firstToken.offset, end: lastToken.offset + lastToken.length)
            }
        }
    }
}

extension SyntaxMap: SourceKitResponseConvertible {

    /**
    Create a SyntaxMap from a SourceKit `editor.open` response.

    - parameter sourceKitResponse: SourceKit `editor.open` response.
    */
    public init(sourceKitResponse response: Response) throws {
        let dict = try response.value(of: Response.Dictionary.self)
        let array = try dict.valueFor(SwiftDocKey.SyntaxMap, of: Response.Array.self)
        try self.init(tokens: array.map(SyntaxToken.init))
    }

    /**
     Create a SyntaxMap from a File to be parsed.

     - parameter file: File to be parsed.
     */
    public init(file: File) throws {
        try self.init(sourceKitResponse: try Request.EditorOpen(file).send())
    }

}

// MARK: CustomStringConvertible

extension SyntaxMap: CustomStringConvertible {
    /// A textual JSON representation of `SyntaxMap`.
    public var description: String {
        do {
            let jsonData = try NSJSONSerialization.dataWithJSONObject(tokens.map { $0.dictionaryValue },
                options: .PrettyPrinted)
            if let jsonString = NSString(data: jsonData, encoding: NSUTF8StringEncoding) as String? {
                return jsonString
            }
        } catch {}
        return "[\n\n]" // Empty JSON Array
    }
}

// MARK: Equatable

extension SyntaxMap: Equatable {}

/**
Returns true if `lhs` SyntaxMap is equal to `rhs` SyntaxMap.

- parameter lhs: SyntaxMap to compare to `rhs`.
- parameter rhs: SyntaxMap to compare to `lhs`.

- returns: True if `lhs` SyntaxMap is equal to `rhs` SyntaxMap.
*/
public func ==(lhs: SyntaxMap, rhs: SyntaxMap) -> Bool {
    // TODO: replace with == once SwiftXPC is gone
    return lhs.tokens.elementsEqual(rhs.tokens)
}
