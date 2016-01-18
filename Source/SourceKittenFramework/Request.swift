//
//  Request.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-03.
//  Copyright (c) 2015 JP Simard. All rights reserved.
//

import Foundation
import SwiftXPC

/// Represents a SourceKit request.
public enum Request {
    /// An `editor.open` request for the given File.
    case EditorOpen(File)
    /// A `cursorinfo` request for an offset in the given file, using the `arguments` given.
    case CursorInfo(file: String, offset: Int64, arguments: [String])
    /// A `codecomplete` request by passing in the file name, contents, offset
    /// for which to generate code completion options and array of compiler arguments.
    case CodeCompletionRequest(file: String, contents: String, offset: Int64, arguments: [String])

    private enum Command: UID {
        case EditorOpen            = "source.request.editor.open"
        case CursorInfo            = "source.request.cursorinfo"
        case CodeCompletionRequest = "source.request.codecomplete"
    }

    private enum Keys: UID {
        case Request           = "key.request"
        case Name              = "key.name"
        case SourceFile        = "key.sourcefile"
        case SourceText        = "key.sourcetext"
        case Offset            = "key.offset"
        case CompilerArguments = "key.compilerargs"
    }

    private var value: SourceKit.Request {
        switch self {
        case let .EditorOpen(file):
            if let path = file.path {
                return .init([
                    Keys.Request:    .init(Command.EditorOpen),
                    Keys.Name:       .init(path),
                    Keys.SourceFile: .init(path)
                ])
            } else {
                return .init([
                    Keys.Request:    .init(Command.EditorOpen),
                    Keys.Name:       .init(String(file.contents.hash)),
                    Keys.SourceText: .init(file.contents)
                ])
            }
        case let .CursorInfo(file, offset, arguments):
            return .init([
                Keys.Request:    .init(Command.CursorInfo),
                Keys.Name:       .init(file),
                Keys.SourceFile: .init(file),
                Keys.Offset:     .init(offset),
                Keys.CompilerArguments: .init(arguments.lazy.map(SourceKit.Request.String)),
            ])
        case let .CodeCompletionRequest(file, contents, offset, arguments):
            return .init([
                Keys.Request:    .init(Command.CodeCompletionRequest),
                Keys.Name:       .init(file),
                Keys.SourceFile: .init(file),
                Keys.SourceText: .init(contents),
                Keys.Offset:     .init(offset),
                Keys.CompilerArguments: .init(arguments.lazy.map(SourceKit.Request.String)),
            ])
        }
    }

    /**
    Create a Request.CursorInfo from a file path and compiler arguments.

    - parameter filePath:  Path of the file to create request.
    - parameter arguments: Compiler arguments.
    */
    internal init?(filePath: String?, arguments: [String]) {
        guard let filePath = filePath else {
            return nil
        }
        self = .CursorInfo(file: filePath, offset: 0, arguments: arguments)
    }

    /**
    Send a Request.CursorInfo by updating its offset. Returns SourceKit response if successful.

    - parameter offset:  Offset to update request.

    - returns: SourceKit response if successful.
    */
    internal func sendAtOffset(offset: Int64) throws -> Response? {
        guard offset != 0, case let .CursorInfo(file, _, arguments) = self else { return nil }
        return try Request.CursorInfo(file: file, offset: offset, arguments: arguments).send()
    }

    /**
     Sends the request to SourceKit and return the response as an XPCDictionary.

     - returns: SourceKit output as an XPC dictionary.
     */
    public func send() throws -> Response {
        return try SourceKit.shared.sendRequest(value)
    }

    /**
    Send a Request.CursorInfo by updating its offset. Returns SourceKit response if successful.

    - parameter offset:  Offset to update request.

    - returns: SourceKit response if successful.
    */
    @available(*, deprecated)
    internal func sendAtOffset(offset: Int64) -> XPCDictionary? {
        guard offset != 0, case let .CursorInfo(file, _, arguments) = self else { return nil }
        return Request.CursorInfo(file: file, offset: offset, arguments: arguments).send()
    }

    /**
    Sends the request to SourceKit and return the response as an XPCDictionary.

    - returns: SourceKit output as an XPC dictionary.
    */
    @available(*, deprecated)
    public func send() -> XPCDictionary {
        guard let response = SourceKit.shared.sendRequest(value) as xpc_object_t? else {
            fatalError("SourceKit response nil for request \(self)")
        }
        return replaceUIDsWithSourceKitStrings(fromXPC(response))
    }
}

// MARK: CustomDebugStringConvertible

extension Request: CustomDebugStringConvertible {
    /// A textual representation of `Request`.
    public var debugDescription: String { return value.debugDescription }
}
