//
//  File.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-03.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation
import SWXMLHash
#if SWIFT_PACKAGE
import SourceKit
#endif

/// Represents a source file.
public final class File {
    /// File path. Nil if initialized directly with `File(contents:)`.
    public let path: String?
    /// File contents.
    public var contents: String
    /// File lines.
    public var lines: [Line]

    /**
    Failable initializer by path. Fails if file contents could not be read as a UTF8 string.

    - parameter path: File path.
    */
    public init?(URL: NSURL) {
        self.path = URL.path
        do {
            contents = try String(contentsOfURL: URL, encoding: NSUTF8StringEncoding)
            lines = contents.lines()
        } catch {
            fputs("Could not read contents of `\(path)`\n", stderr)
            // necessary to set contents & lines because of rdar://21744509
            contents = ""
            lines = []
            return nil
        }
    }

    /**
    Failable initializer by path. Fails if file contents could not be read as a UTF8 string.

    - parameter path: File path.
    */
    public convenience init?(path: String) {
        self.init(URL: .init(fileURLWithPath: path, isDirectory: false))
    }

    /**
    Initializer by file contents. File path is nil.

    - parameter contents: File contents.
    */
    public init(contents: String) {
        path = nil
        self.contents = contents
        lines = contents.lines()
    }

}

extension File {

    /**
    Parse source declaration string from SourceKit dictionary.

    - parameter dictionary: SourceKit dictionary to extract declaration from.

    - returns: Source declaration if successfully parsed.
    */
    func parseDeclaration(dictionary: [String: SourceKitRepresentable]) -> String? {
        guard cursorHasParseableBody(dictionary) else { return nil }

        return SwiftDocKey.getOffset(dictionary).flatMap { start in
            let end = SwiftDocKey.getBodyOffset(dictionary).map { Int($0) }
            let start = Int(start)
            let length = (end ?? start) - start
            return contents.substringLinesWithByteRange(start: start, length: length)?
                .stringByTrimmingWhitespaceAndOpeningCurlyBrace()
        }
    }

    /**
    Parses an input dictionary with comment mark names, cursor information, and
    parsed declarations into the top-level array of source structures.

    - parameter dictionary:        Dictionary to process.
    - parameter cursorInfoRequest: Cursor.Info request to get nested declaration information.
    */
    func processCursorInfoDictionary(dictionary: [String: SourceKitRepresentable], cursorInfoRequest: sourcekitd_object_t? = nil) throws -> [SwiftDeclaration] {
        var dictionary = dictionary
        let syntaxMapData = dictionary.removeValueForKey(SwiftDocKey.SyntaxMap.rawValue) as? [SourceKitRepresentable]
        let syntaxMap = syntaxMapData.map(SyntaxMap.init)

        var decls = [SwiftDeclaration]()
        if let rootDecl = processCursorInfoDictionaryItem(dictionary, cursorInfoRequest: cursorInfoRequest, syntaxMap: syntaxMap) {
            decls.append(rootDecl)
        } else {
            decls += newSubstructure(dictionary, cursorInfoRequest: cursorInfoRequest, syntaxMap: syntaxMap)
        }

        if let syntaxMap = syntaxMap, cursorInfoRequest = cursorInfoRequest {
            let documentedTokenOffsets = contents.documentedTokenOffsets(syntaxMap)
            let offsetMap = generateOffsetMap(documentedTokenOffsets, declarations: decls)
            for offset in offsetMap.keys.reverse() { // Do this in reverse to insert the doc at the correct offset
                let response = try Request.failableSendCursorInfoRequest(cursorInfoRequest, atOffset: offset)
                if let newDecl = processCursorInfoDictionaryItem(response, cursorInfoRequest: nil, syntaxMap: syntaxMap), parentOffset = offsetMap[offset] {
                    insertDeclaration(newDecl, into: &decls, atOffset: parentOffset)
                }
            }
        }

        return decls
    }

}

extension SwiftDeclaration {

    /**
     Returns true if path is nil or if path has the same last path component
     as the  `file`.

     - parameter file: File whose `path` to check against..
     */
    func shouldTreatSameAsSameFile(file: File) -> Bool {
        return file.path == location.filename
    }

}

private extension File {

    /**
     Returns true if the dictionary represents a source declaration or a mark-style comment.

     - parameter dictionary: Dictionary to parse.
     */
    func isDeclarationOrCommentMark(dictionary: [String: SourceKitRepresentable]) -> Bool {
        if let kind = SwiftDocKey.getKind(dictionary) {
            return kind != SwiftDeclarationKind.VarParameter.rawValue &&
                (kind == SyntaxKind.CommentMark.rawValue || SwiftDeclarationKind(rawValue: kind) != nil)
        }
        return false
    }

    /**
    Extract mark-style comment string from doc dictionary. e.g. '// MARK: - The Name'

    - parameter dictionary: Doc dictionary to parse.

    - returns: Mark name if successfully parsed.
    */
    func markNameFromDictionary(dictionary: [String: SourceKitRepresentable]) -> String? {
        precondition(SwiftDocKey.getKind(dictionary)! == SyntaxKind.CommentMark.rawValue)
        guard let offset = SwiftDocKey.getOffset(dictionary).map({ Int($0) }),
            length = SwiftDocKey.getLength(dictionary).map({ Int($0) }) else {
            return nil
        }
        return contents.rangeForUTF8(offset ..< offset + length).map { contents[$0] }
    }

    func byteRangeToLocationRange(byteRange: Range<Int>, dictionary: [String: SourceKitRepresentable]) -> SwiftRange? {
        guard let ranges = contents.lineRangeForUTF8(byteRange) else { return nil }

        let filename = SwiftDocKey.getFilePath(dictionary) ?? path
        let start = SwiftLocation(filename: filename, line: ranges.start.line, column: ranges.start.column, offset: byteRange.startIndex)
        let end = SwiftLocation(filename: filename, line: ranges.end.line, column: ranges.end.column, offset: byteRange.endIndex)
        return start ..< end
    }

    func parseScopeLocation(dictionary: [String: SourceKitRepresentable]) -> SwiftLocation? {
        guard let byteStart = SwiftDocKey.getOffset(dictionary).map({ Int($0) }) else { return nil }

        let filename = SwiftDocKey.getFilePath(dictionary) ?? path
        guard let ranges = contents.lineRangeForUTF8(byteStart ..< byteStart) else { return nil }

        return SwiftLocation(filename: filename, line: ranges.start.line, column: ranges.start.column, offset: byteStart)
    }

    func parseExtent(dictionary: [String: SourceKitRepresentable]) -> SwiftRange? {
        guard cursorHasParseableBody(dictionary),
            let start = SwiftDocKey.getOffset(dictionary).map({ Int($0) }) else { return nil }

        let end = SwiftDocKey.getBodyOffset(dictionary).flatMap { bodyOffset in
            SwiftDocKey.getBodyLength(dictionary).map { bodyLength in
                Int(bodyOffset + bodyLength)
            }
            } ?? start

        return byteRangeToLocationRange(start ..< end, dictionary: dictionary)
    }

    func parseNameExtent(dictionary: [String: SourceKitRepresentable]) -> SwiftRange? {
        guard let nameOffset = SwiftDocKey.getNameOffset(dictionary).flatMap({ Int($0) }),
            nameLength = SwiftDocKey.getNameLength(dictionary).flatMap({ Int($0) }) else {
                return nil
        }

        return byteRangeToLocationRange(nameOffset ..< nameOffset + nameLength, dictionary: dictionary)
    }

    func parseBodyExtent(dictionary: [String: SourceKitRepresentable]) -> SwiftRange? {
        guard cursorHasParseableBody(dictionary),
            let byteStart = SwiftDocKey.getOffset(dictionary).map({ Int($0) }) else { return nil }

        let byteRange: Range<Int>
        if let bodyOffset = SwiftDocKey.getBodyOffset(dictionary), bodyLength = SwiftDocKey.getBodyLength(dictionary) {
            byteRange = byteStart ..< Int(bodyOffset + bodyLength)
        } else {
            byteRange = byteStart ..< byteStart
        }

        return byteRangeToLocationRange(byteRange, dictionary: dictionary)
    }

    func processCursorInfoDictionaryItem(dictionary: [String: SourceKitRepresentable], cursorInfoRequest: sourcekitd_object_t?, syntaxMap: SyntaxMap?) -> SwiftDeclaration? {
        var dictionary = dictionary
        if let cursorInfoRequest = cursorInfoRequest {
            addCommentMarkNamesToCursorInfo(&dictionary, cursorInfoRequest: cursorInfoRequest)
        }

        let docs: SwiftCursorDocumentation?
        if let xmlDocs = SwiftDocKey.getFullXMLDocs(dictionary), offset = SwiftDocKey.getOffset(dictionary) {
            docs = SwiftCursorDocumentation(XMLDocs: xmlDocs, at: offset)
        } else {
            docs = nil
        }

        guard let kind = SwiftDocKey.getKind(dictionary).flatMap({ SwiftDeclarationKind(rawValue: $0) }),
            location = docs?.location ?? parseScopeLocation(dictionary) else {
            return nil
        }

        var decl = SwiftDeclaration(kind: kind, location: location)
        decl.extent ?= parseExtent(dictionary)
        decl.accessibility ?= SwiftDocKey.getAccessibility(dictionary).flatMap({ SwiftAccessibility(rawValue: $0) })
        decl.name = docs?.name ?? SwiftDocKey.getName(dictionary)
        decl.symbol = docs?.symbol
        decl.declaration = docs?.declaration ?? parseDeclaration(dictionary)
        decl.documentation ?= docs?.documentation
        decl.commentBody = syntaxMap.flatMap { getDocumentationCommentBody(dictionary, syntaxMap: $0) }
        decl.children = newSubstructure(dictionary, cursorInfoRequest: cursorInfoRequest, syntaxMap: syntaxMap)
        decl.nameExtent = parseNameExtent(dictionary)
        decl.bodyExtent = parseBodyExtent(dictionary)

        return decl
    }

    func newSubstructure(dictionary: [String: SourceKitRepresentable], cursorInfoRequest: sourcekitd_object_t?, syntaxMap: SyntaxMap?) -> [SwiftDeclaration] {
        guard let children = SwiftDocKey.getSubstructure(dictionary) else { return [] }
        return children.lazy.map { $0 as! [String: SourceKitRepresentable] }
            .filter(isDeclarationOrCommentMark)
            .flatMap { processCursorInfoDictionaryItem($0, cursorInfoRequest: cursorInfoRequest, syntaxMap: syntaxMap) }
    }

    func addCommentMarkNamesToCursorInfo(inout dictionary: [String: SourceKitRepresentable], cursorInfoRequest: sourcekitd_object_t) {
        // Only update dictionaries with a 'kind' key
        guard let kind = SwiftDocKey.getKind(dictionary) else { return }

        if kind == SyntaxKind.CommentMark.rawValue {
            // Update comment marks
            if let markName = markNameFromDictionary(dictionary) {
                dictionary[SwiftDocKey.Name.rawValue] = markName
            }
        } else if let decl = SwiftDeclarationKind(rawValue: kind),
            offset = SwiftDocKey.getNameOffset(dictionary) where decl != .VarParameter {
            // Update if kind is a declaration (but not a parameter)
            var updateDict = Request.sendCursorInfoRequest(cursorInfoRequest, atOffset: offset) ?? [:]

            // Skip kinds, since values from editor.open are more accurate than cursorinfo
            updateDict[SwiftDocKey.Kind.rawValue] = nil

            mergeInPlace(&dictionary, updateDict)
        }
    }

    func shouldInsertInto(declaration: SwiftDeclaration, at offset: Int) -> Bool {
        return ((offset == 0) || (declaration.shouldTreatSameAsSameFile(self) && declaration.location.offset == offset))
    }

    func insertDeclaration(declaration: SwiftDeclaration, inout into declarations: [SwiftDeclaration], atOffset offset: Int) -> Bool {
        for (parentIndex, var parent) in declarations.enumerate() {
            if shouldInsertInto(parent, at: offset) {
                var insertIndex = parent.children.endIndex
                for (index, structure) in parent.children.reverse().enumerate() {
                    if structure.location.offset < offset { break }
                    insertIndex = parent.children.endIndex - index
                }
                parent.children.insert(declaration, atIndex: insertIndex)
                declarations[parentIndex] = parent
                return true
            }

            if insertDeclaration(declaration, into: &parent.children, atOffset: offset) {
                declarations[parentIndex] = parent
                return true
            }
        }

        return false
    }

    /**
    Returns true if the input dictionary contains a parseable declaration.

    - parameter dictionary: Dictionary to parse.
    */
    func cursorHasParseableBody(dictionary: [String: SourceKitRepresentable]) -> Bool {
        let sameFile                = SwiftDocKey.getFilePath(dictionary) == path
        let hasTypeName             = SwiftDocKey.getTypeName(dictionary) != nil
        let hasAnnotatedDeclaration = SwiftDocKey.getAnnotatedDeclaration(dictionary) != nil
        let hasOffset               = SwiftDocKey.getOffset(dictionary) != nil
        let isntExtension           = SwiftDocKey.getKind(dictionary) != SwiftDeclarationKind.Extension.rawValue
        return sameFile && hasTypeName && hasAnnotatedDeclaration && hasOffset && isntExtension
    }

    /**
    Parses `dictionary`'s documentation comment body.

    - parameter dictionary: Dictionary to parse.
    - parameter syntaxMap:  SyntaxMap for current file.

    - returns: `dictionary`'s documentation comment body as a string, without any documentation
               syntax (`/** ... */` or `/// ...`).
    */
    func getDocumentationCommentBody(dictionary: [String: SourceKitRepresentable], syntaxMap: SyntaxMap) -> String? {
        guard let offset = SwiftDocKey.getOffset(dictionary).map({ Int($0) }),
            commentByteRange = syntaxMap.commentRangeBeforeOffset(offset) else { return nil }

        let commentEndLine = contents.lineRangeForUTF8(commentByteRange.endIndex ..< commentByteRange.endIndex)?.end.line
        let tokenStartLine = contents.lineRangeForUTF8(offset ..< offset)?.start.line
        guard commentEndLine == tokenStartLine || commentEndLine == tokenStartLine?.predecessor() else {
            return nil
        }

        return contents.rangeForUTF8(commentByteRange).flatMap {
            contents[$0].commentBody()
        }
    }

}

infix operator ?= {
    associativity right
    precedence 90
    assignment
}

private func ?= <T>(inout lhs: T, @autoclosure rhs: () throws -> T?) rethrows {
    if let newValue = try rhs() {
        lhs = newValue
    }
}
