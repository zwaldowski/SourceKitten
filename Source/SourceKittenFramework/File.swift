//
//  File.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-03.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation
import SwiftXPC
import SWXMLHash

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
    public init?(path: String) {
        self.path = (path as NSString).absolutePathRepresentation()
        do {
            contents = try NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String
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
    Initializer by file contents. File path is nil.

    - parameter contents: File contents.
    */
    public init(contents: String) {
        path = nil
        self.contents = contents
        lines = contents.lines()
    }

    /**
    Parse source declaration string from SourceKit dictionary.

    - parameter dictionary: SourceKit dictionary to extract declaration from.

    - returns: Source declaration if successfully parsed.
    */
    public func parseDeclaration(dictionary: Response.Dictionary) -> String? {
        guard shouldParseDeclaration(dictionary) else { return nil }
        do {
            let start = try Int(dictionary.valueFor(SwiftDocKey.Offset, of: Int64.self))
            let end = try? Int(dictionary.valueFor(SwiftDocKey.BodyOffset, of: Int64.self))
            let length = (end ?? start) - start
            return contents.substringLinesWithByteRange(start: start, length: length)?
                .stringByTrimmingWhitespaceAndOpeningCurlyBrace()
        } catch {
            return nil
        }
    }

    /**
    Parse line numbers containing the declaration's implementation from SourceKit dictionary.
    
    - parameter dictionary: SourceKit dictionary to extract declaration from.
    
    - returns: Line numbers containing the declaration's implementation.
    */
    public func parseScopeRange(dictionary: Response.Dictionary) -> (start: Int, end: Int)? {
        guard shouldParseDeclaration(dictionary) else { return nil }
        do {
            let start = try Int(dictionary.valueFor(SwiftDocKey.Offset, of: Int64.self))
            let end: Int
            do {
                let bodyOffset = try dictionary.valueFor(SwiftDocKey.BodyOffset, of: Int64.self)
                let bodyLength = try dictionary.valueFor(SwiftDocKey.BodyLength, of: Int64.self)
                end = Int(bodyOffset + bodyLength)
            } catch {
                end = start
            }
            let length = end - start
            return contents.lineRangeWithByteRange(start: start, length: length)
        } catch {
            return nil
        }
    }

    /**
    Extract mark-style comment string from doc dictionary. e.g. '// MARK: - The Name'

    - parameter dictionary: Doc dictionary to parse.

    - returns: Mark name if successfully parsed.
    */
    private func markNameFromDictionary(dictionary: Response.Dictionary) -> String? {
        precondition(try! dictionary.uidFor(SwiftDocKey.Kind, of: SyntaxKind.self) == .CommentMarker)
        do {
            let offset = try Int(dictionary.valueFor(SwiftDocKey.Offset, of: Int64.self))
            let length = try Int(dictionary.valueFor(SwiftDocKey.Length, of: Int64.self))
            guard let fileContentsData = contents.dataUsingEncoding(NSUTF8StringEncoding) else { return nil }
            let subdata = fileContentsData.subdataWithRange(NSRange(location: offset, length: length))
            return String(data: subdata, encoding: NSUTF8StringEncoding)
        } catch {
            return nil
        }
    }
















    /**
    Parse source declaration string from XPC dictionary.

    - parameter dictionary: XPC dictionary to extract declaration from.

    - returns: Source declaration if successfully parsed.
    */
    @available(*, deprecated)
    public func parseDeclaration(dictionary: XPCDictionary) -> String? {
        if !shouldParseDeclaration(dictionary) {
            return nil
        }
        return SwiftDocKeyOld.getOffset(dictionary).flatMap { start in
            let end = SwiftDocKeyOld.getBodyOffset(dictionary).map { Int($0) }
            let start = Int(start)
            let length = (end ?? start) - start
            return contents.substringLinesWithByteRange(start: start, length: length)?
                .stringByTrimmingWhitespaceAndOpeningCurlyBrace()
        }
    }

    /**
    Parse line numbers containing the declaration's implementation from XPC dictionary.
    
    - parameter dictionary: XPC dictionary to extract declaration from.
    
    - returns: Line numbers containing the declaration's implementation.
    */
    @available(*, deprecated)
    public func parseScopeRange(dictionary: XPCDictionary) -> (start: Int, end: Int)? {
        if !shouldParseDeclaration(dictionary) {
            return nil
        }
        return SwiftDocKeyOld.getOffset(dictionary).flatMap { start in
            let start = Int(start)
            let end = SwiftDocKeyOld.getBodyOffset(dictionary).flatMap { bodyOffset in
                return SwiftDocKeyOld.getBodyLength(dictionary).map { bodyLength in
                    return Int(bodyOffset + bodyLength)
                }
            } ?? start
            let length = end - start
            return contents.lineRangeWithByteRange(start: start, length: length)
        }
    }

    /**
    Extract mark-style comment string from doc dictionary. e.g. '// MARK: - The Name'

    - parameter dictionary: Doc dictionary to parse.

    - returns: Mark name if successfully parsed.
    */
    @available(*, deprecated)
    private func markNameFromDictionary(dictionary: XPCDictionary) -> String? {
        precondition(SwiftDocKeyOld.getKind(dictionary)! == SyntaxKindOld.CommentMark.rawValue)
        let offset = Int(SwiftDocKeyOld.getOffset(dictionary)!)
        let length = Int(SwiftDocKeyOld.getLength(dictionary)!)
        if let fileContentsData = contents.dataUsingEncoding(NSUTF8StringEncoding),
            subdata = Optional(fileContentsData.subdataWithRange(NSRange(location: offset, length: length))),
            substring = NSString(data: subdata, encoding: NSUTF8StringEncoding) as String? {
            return substring
        }
        return nil
    }












    /**
    Returns a copy of the input dictionary with comment mark names, cursor.info information and
    parsed declarations for the top-level of the input dictionary and its substructures.

    - parameter dictionary:        Dictionary to process.
    - parameter cursorInfoRequest: Cursor.Info request to get declaration information.
    */
    public func processDictionary(dictionary: XPCDictionary, cursorInfoRequest: Request? = nil, syntaxMap: SyntaxMap? = nil) -> XPCDictionary {
        var dictionary = dictionary
        
        if let cursorInfoRequest = cursorInfoRequest {
            dictionary = merge(
                dictionary,
                dictWithCommentMarkNamesCursorInfo(dictionary, cursorInfoRequest: cursorInfoRequest)
            )
        }

        // Parse declaration and add to dictionary
        if let parsedDeclaration = parseDeclaration(dictionary) {
            dictionary[SwiftDocKeyOld.ParsedDeclaration.rawValue] = parsedDeclaration
        }

        // Parse scope range and add to dictionary
        if let parsedScopeRange = parseScopeRange(dictionary) {
            dictionary[SwiftDocKeyOld.ParsedScopeStart.rawValue] = Int64(parsedScopeRange.start)
            dictionary[SwiftDocKeyOld.ParsedScopeEnd.rawValue] = Int64(parsedScopeRange.end)
        }

        // Parse `key.doc.full_as_xml` and add to dictionary
        if let parsedXMLDocs = (SwiftDocKeyOld.getFullXMLDocs(dictionary).flatMap(parseFullXMLDocs)) {
            dictionary = merge(dictionary, parsedXMLDocs)

            // Parse documentation comment and add to dictionary
            if let commentBody = (syntaxMap.flatMap { getDocumentationCommentBody(dictionary, syntaxMap: $0) }) {
                dictionary[SwiftDocKeyOld.DocumentationComment.rawValue] = commentBody
            }
        }

        // Update substructure
        if let substructure = newSubstructure(dictionary, cursorInfoRequest: cursorInfoRequest, syntaxMap: syntaxMap) {
            dictionary[SwiftDocKeyOld.Substructure.rawValue] = substructure
        }
        return dictionary
    }

    /**
    Returns a copy of the input dictionary with additional cursorinfo information at the given
    `documentationTokenOffsets` that haven't yet been documented.

    - parameter dictionary:             Dictionary to insert new docs into.
    - parameter documentedTokenOffsets: Offsets that are likely documented.
    - parameter cursorInfoRequest:      Cursor.Info request to get declaration information.
    */
    internal func furtherProcessDictionary(dictionary: XPCDictionary, documentedTokenOffsets: [Int], cursorInfoRequest: Request, syntaxMap: SyntaxMap) -> XPCDictionary {
        var dictionary = dictionary
        let offsetMap = generateOffsetMap(documentedTokenOffsets, dictionary: dictionary)
        for offset in offsetMap.keys.reverse() { // Do this in reverse to insert the doc at the correct offset
            let response = processDictionary(cursorInfoRequest.sendAtOffset(numericCast(offset))!, syntaxMap: syntaxMap)
            if let kind = SwiftDocKeyOld.getKind(response),
                _ = SwiftDeclarationKindOld(rawValue: kind),
                parentOffset = offsetMap[offset].flatMap({ Int64($0) }),
                inserted = insertDoc(response, parent: dictionary, offset: parentOffset) {
                dictionary = inserted
            }
        }
        return dictionary
    }

    /**
    Update input dictionary's substructure by running `processDictionary(_:cursorInfoRequest:syntaxMap:)` on
    its elements, only keeping comment marks and declarations.

    - parameter dictionary:        Input dictionary to process its substructure.
    - parameter cursorInfoRequest: Cursor.Info request to get declaration information.

    - returns: A copy of the input dictionary's substructure processed by running
               `processDictionary(_:cursorInfoRequest:syntaxMap:)` on its elements, only keeping comment marks
               and declarations.
    */
    private func newSubstructure(dictionary: XPCDictionary, cursorInfoRequest: Request?, syntaxMap: SyntaxMap?) -> XPCArray? {
        return SwiftDocKeyOld.getSubstructure(dictionary)?
            .map({ $0 as! XPCDictionary })
            .filter(isDeclarationOrCommentMark)
            .map {
                processDictionary($0, cursorInfoRequest: cursorInfoRequest, syntaxMap: syntaxMap)
        }
    }

    /**
    Returns an updated copy of the input dictionary with comment mark names and cursor.info information.

    - parameter dictionary:        Dictionary to update.
    - parameter cursorInfoRequest: Cursor.Info request to get declaration information.
    */
    private func dictWithCommentMarkNamesCursorInfo(dictionary: XPCDictionary, cursorInfoRequest: Request) -> XPCDictionary? {
        if let kind = SwiftDocKeyOld.getKind(dictionary) {
            // Only update dictionaries with a 'kind' key
            if kind == SyntaxKindOld.CommentMark.rawValue {
                // Update comment marks
                if let markName = markNameFromDictionary(dictionary) {
                    return [SwiftDocKeyOld.Name.rawValue: markName]
                }
            } else if let decl = SwiftDeclarationKindOld(rawValue: kind),
                offset = SwiftDocKeyOld.getNameOffset(dictionary) where decl != .VarParameter {
                // Update if kind is a declaration (but not a parameter)
                var updateDict = cursorInfoRequest.sendAtOffset(offset) ?? XPCDictionary()

                // Skip kinds, since values from editor.open are more accurate than cursorinfo
                updateDict.removeValueForKey(SwiftDocKeyOld.Kind.rawValue)
                return updateDict
            }
        }
        return nil
    }















    
    /**
    Returns whether or not a doc should be inserted into a parent at the provided offset.

    - parameter parent: Parent dictionary to evaluate.
    - parameter offset: Offset to search for in parent dictionary.

    - returns: True if a doc should be inserted in the parent at the provided offset.
    */
    @available(*, deprecated)
    private func shouldInsert(parent: XPCDictionary, offset: Int64) -> Bool {
        return SwiftDocKeyOld.getSubstructure(parent) != nil &&
            ((offset == 0) ||
            (shouldTreatAsSameFile(parent) && SwiftDocKeyOld.getOffset(parent) == offset))
    }

    /**
    Returns whether or not a doc should be inserted into a parent at the provided offset.

    - parameter parent: Parent dictionary to evaluate.
    - parameter offset: Offset to search for in parent dictionary.

    - returns: True if a doc should be inserted in the parent at the provided offset.
    */
    private func shouldInsert(parent: Response.Dictionary, offset: Int64) -> Bool {
        guard (try? parent.valueFor(SwiftDocKey.Substructure, of: Response.Array.self)) != nil else {
            return false
        }

        do {
            return try offset == 0 || (shouldTreatAsSameFile(parent) && parent.valueFor(SwiftDocKey.Offset, of: Int64.self) == offset)
        } catch {
            return false
        }
    }

    /**
    Inserts a document dictionary at the specified offset.
    Parent will be traversed until the offset is found.
    Returns nil if offset could not be found.

    - parameter doc:    Document dictionary to insert.
    - parameter parent: Parent to traverse to find insertion point.
    - parameter offset: Offset to insert document dictionary.

    - returns: Parent with doc inserted if successful.
    */
    private func insertDoc(doc: XPCDictionary, parent: XPCDictionary, offset: Int64) -> XPCDictionary? {
        var parent = parent
        if shouldInsert(parent, offset: offset) {
            var substructure = SwiftDocKeyOld.getSubstructure(parent)!
            var insertIndex = substructure.count
            for (index, structure) in substructure.reverse().enumerate() {
                if SwiftDocKeyOld.getOffset(structure as! XPCDictionary)! < offset {
                    break
                }
                insertIndex = substructure.count - index
            }
            substructure.insert(doc, atIndex: insertIndex)
            parent[SwiftDocKeyOld.Substructure.rawValue] = substructure
            return parent
        }
        for case (let key, var subArray as XPCArray) in parent {
            for case (let i, let dictParent as XPCDictionary) in subArray.enumerate() {
                guard let subDict = insertDoc(doc, parent: dictParent, offset: offset) else { continue }
                subArray[i] = subDict
                parent[key] = subArray
                return parent
            }
        }
        return nil
    }

    /**
    Returns true if path is nil or if path has the same last path component as `key.filepath` in the
    input dictionary.

    - parameter dictionary: Dictionary to parse.
     */
    @available(*, deprecated)
    internal func shouldTreatAsSameFile(dictionary: XPCDictionary) -> Bool {
        return path == SwiftDocKeyOld.getFilePath(dictionary)
    }

    /**
    Returns true if the input dictionary contains a parseable declaration.

    - parameter dictionary: Dictionary to parse.
    */
    @available(*, deprecated)
    private func shouldParseDeclaration(dictionary: XPCDictionary) -> Bool {
        let sameFile                = shouldTreatAsSameFile(dictionary)
        let hasTypeName             = SwiftDocKeyOld.getTypeName(dictionary) != nil
        let hasAnnotatedDeclaration = SwiftDocKeyOld.getAnnotatedDeclaration(dictionary) != nil
        let hasOffset               = SwiftDocKeyOld.getOffset(dictionary) != nil
        let isntExtension           = SwiftDocKeyOld.getKind(dictionary) != SwiftDeclarationKindOld.Extension.rawValue
        return sameFile && hasTypeName && hasAnnotatedDeclaration && hasOffset && isntExtension
    }

    /**
    Parses `dictionary`'s documentation comment body.

    - parameter dictionary: Dictionary to parse.
    - parameter syntaxMap:  SyntaxMap for current file.

    - returns: `dictionary`'s documentation comment body as a string, without any documentation
               syntax (`/** ... */` or `/// ...`).
    */
    @available(*, deprecated)
    public func getDocumentationCommentBody(dictionary: XPCDictionary, syntaxMap: SyntaxMap) -> String? {
        return SwiftDocKeyOld.getOffset(dictionary).flatMap { offset in
            return syntaxMap.commentRangeBeforeOffset(Int(offset)).flatMap { commentByteRange in
                let commentEndLine = (contents as NSString).lineAndCharacterForByteOffset(commentByteRange.endIndex)?.line
                let tokenStartLine = (contents as NSString).lineAndCharacterForByteOffset(Int(offset))?.line
                guard commentEndLine == tokenStartLine || commentEndLine == tokenStartLine?.predecessor() else {
                    return nil
                }
                return contents.byteRangeToNSRange(start: commentByteRange.startIndex, length: commentByteRange.endIndex - commentByteRange.startIndex).flatMap { nsRange in
                    return contents.commentBody(nsRange)
                }
            }
        }
    }




    

    /**
    Returns true if path is nil or if path has the same last path component as `key.filepath` in the
    input dictionary.

    - parameter dictionary: Dictionary to parse.
    */
    internal func shouldTreatAsSameFile(dictionary: Response.Dictionary) -> Bool {
        return path == (try? dictionary.valueFor(SwiftDocKey.FilePath))
    }

    /**
    Returns true if the input dictionary contains a parseable declaration.

    - parameter dictionary: Dictionary to parse.
    */
    private func shouldParseDeclaration(dictionary: Response.Dictionary) -> Bool {
        let sameFile                = shouldTreatAsSameFile(dictionary)
        let hasTypeName             = (try? dictionary.valueFor(SwiftDocKey.TypeName, of: String.self)) != nil
        let hasAnnotatedDeclaration = (try? dictionary.valueFor(SwiftDocKey.AnnotatedDeclaration, of: String.self)) != nil
        let hasOffset               = (try? dictionary.valueFor(SwiftDocKey.Offset, of: Int64.self)) != nil
        let isntExtension           = (try? dictionary.uidFor(SwiftDocKey.Kind, of: SwiftDeclarationKind.self)) != SwiftDeclarationKind.Extension
        return sameFile && hasTypeName && hasAnnotatedDeclaration && hasOffset && isntExtension
    }

    /**
    Parses `dictionary`'s documentation comment body.

    - parameter dictionary: Dictionary to parse.
    - parameter syntaxMap:  SyntaxMap for current file.

    - returns: `dictionary`'s documentation comment body as a string, without any documentation
               syntax (`/** ... */` or `/// ...`).
    */
    public func getDocumentationCommentBody(dictionary: Response.Dictionary, syntaxMap: SyntaxMap) -> String? {
        do {
            let offset = try dictionary.valueFor(SwiftDocKey.Offset, of: Int64.self)
            guard let commentByteRange = syntaxMap.commentRangeBeforeOffset(Int(offset)) else { return nil }
            let commentEndLine = (contents as NSString).lineAndCharacterForByteOffset(commentByteRange.endIndex)?.line
            let tokenStartLine = (contents as NSString).lineAndCharacterForByteOffset(Int(offset))?.line
            guard commentEndLine == tokenStartLine || commentEndLine == tokenStartLine?.predecessor(),
                let nsRange = contents.byteRangeToNSRange(start: commentByteRange.startIndex, length: commentByteRange.endIndex - commentByteRange.startIndex) else {
                return nil
            }
            return contents.commentBody(nsRange)
        } catch {
            return nil
        }
    }

}

/**
Traverse the dictionary replacing SourceKit UIDs with their string value.

- parameter dictionary: Dictionary to replace UIDs.

- returns: Dictionary with UIDs replaced by strings.
*/
@available(*, deprecated)
internal func replaceUIDsWithSourceKitStrings(dictionary: XPCDictionary) -> XPCDictionary {
    var dictionary = dictionary
    for (key, value) in dictionary {
        if let uidBits = value as? UInt64, uid = UID(bitPattern: uidBits) {
            dictionary[key] = String(uid)
        } else if let array = value as? XPCArray {
            dictionary[key] = array.map { replaceUIDsWithSourceKitStrings($0 as! XPCDictionary) } as XPCArray
        } else if let dict = value as? XPCDictionary {
            dictionary[key] = replaceUIDsWithSourceKitStrings(dict)
        }
    }
    return dictionary
}

/**
Returns true if the dictionary represents a source declaration or a mark-style comment.

- parameter dictionary: Dictionary to parse.
*/
@available(*, deprecated)
private func isDeclarationOrCommentMark(dictionary: XPCDictionary) -> Bool {
    if let kind = SwiftDocKeyOld.getKind(dictionary) {
        return kind != SwiftDeclarationKindOld.VarParameter.rawValue &&
            (kind == SyntaxKindOld.CommentMark.rawValue || SwiftDeclarationKindOld(rawValue: kind) != nil)
    }
    return false
}

/**
Returns true if the dictionary represents a source declaration or a mark-style comment.

- parameter dictionary: Dictionary to parse.
*/
private func isDeclarationOrCommentMark(dictionary: Response.Dictionary) -> Bool {
    do {
        let kind = try dictionary.valueFor(SwiftDocKey.Kind, of: UID.self)
        return kind != SwiftDeclarationKind.VarParam.rawValue &&
            (kind == SyntaxKind.CommentMarker.rawValue || SwiftDeclarationKind(rawValue: kind) != nil)
    } catch {
        return false
    }
}

/**
Parse XML from `key.doc.full_as_xml` from `cursor.info` request.

- parameter xmlDocs: Contents of `key.doc.full_as_xml` from SourceKit.

- returns: XML parsed as an `XPCDictionary`.
*/
@available(*, deprecated)
public func parseFullXMLDocs(xmlDocs: String) -> XPCDictionary? {
    let cleanXMLDocs = xmlDocs.stringByReplacingOccurrencesOfString("<rawHTML>", withString: "")
        .stringByReplacingOccurrencesOfString("</rawHTML>", withString: "")
        .stringByReplacingOccurrencesOfString("<codeVoice>", withString: "`")
        .stringByReplacingOccurrencesOfString("</codeVoice>", withString: "`")
    return SWXMLHash.parse(cleanXMLDocs).children.first.map { rootXML in
        var docs = XPCDictionary()
        docs[SwiftDocKeyOld.DocType.rawValue] = rootXML.element?.name
        docs[SwiftDocKeyOld.DocFile.rawValue] = rootXML.element?.attributes["file"]
        docs[SwiftDocKeyOld.DocLine.rawValue] = rootXML.element?.attributes["line"].flatMap {
            Int64($0)
        }
        docs[SwiftDocKeyOld.DocColumn.rawValue] = rootXML.element?.attributes["column"].flatMap {
            Int64($0)
        }
        docs[SwiftDocKeyOld.DocName.rawValue] = rootXML["Name"].element?.text
        docs[SwiftDocKeyOld.USR.rawValue] = rootXML["USR"].element?.text
        docs[SwiftDocKeyOld.DocDeclaration.rawValue] = rootXML["Declaration"].element?.text
        let parameters = rootXML["Parameters"].children
        if parameters.count > 0 {
            docs[SwiftDocKeyOld.DocParameters.rawValue] = parameters.map {
                [
                    "name": $0["Name"].element?.text ?? "",
                    "discussion": childrenAsArray($0["Discussion"]) ?? []
                ] as XPCDictionary
            } as XPCArray
        }
        docs[SwiftDocKeyOld.DocDiscussion.rawValue] = childrenAsArray(rootXML["Discussion"])
        docs[SwiftDocKeyOld.DocResultDiscussion.rawValue] = childrenAsArray(rootXML["ResultDiscussion"])
        return docs
    }
}

/**
Returns an `XPCArray` of `XPCDictionary` items from `indexer` children, if any.

- parameter indexer: `XMLIndexer` to traverse.
*/
private func childrenAsArray(indexer: XMLIndexer) -> XPCArray? {
    let children = indexer.children
    if children.count > 0 {
        return children.flatMap({ $0.element }).map {
            [$0.name: $0.text ?? ""] as XPCDictionary
        } as XPCArray
    }
    return nil
}
