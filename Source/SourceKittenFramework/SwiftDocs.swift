//
//  SwiftDocs.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-03.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation
#if SWIFT_PACKAGE
import SourceKit
#endif

/// Represents docs for a Swift file.
public struct SwiftDocs {
    /// Documented File.
    public let file: File

    /// Docs information as a list of declarations.
    public let declarations: [SwiftDeclaration]

    /**
    Create docs for the specified Swift file and compiler arguments.

    - parameter file:      Swift file to document.
    - parameter arguments: compiler arguments to pass to SourceKit.
    */
    public init?(file: File, arguments: [String]) {
        do {
            try self.init(
                file: file,
                dictionary: try Request.EditorOpen(file).failableSend(),
                cursorInfoRequest: Request.cursorInfoRequestForFilePath(file.path, arguments: arguments)
            )
        } catch let error as Request.Error {
            fputs(error.description, stderr)
            return nil
        } catch {
            return nil
        }
    }

    private init(file: File, dictionary: [String: SourceKitRepresentable], cursorInfoRequest: sourcekitd_object_t?) throws {
        self.file = file
        self.declarations = try file.processCursorInfoDictionary(dictionary, cursorInfoRequest: cursorInfoRequest)
    }
}

extension SwiftDocs: Serializable {

    /// A serialized representation of `self`.
    func toOutput() -> Output {
        return .Object([ file.path ?? "<No File>": [
            SwiftDocKey.Substructure.rawValue: declarations.toObject(),
            SwiftDocKey.Offset.rawValue: 0,
            SwiftDocKey.Length.rawValue: file.contents.utf16.count,
            SwiftDocKey.DiagnosticStage.rawValue: "",
        ]])
    }

}

// MARK: CustomStringConvertible

extension SwiftDocs: CustomStringConvertible {

    /// A textual JSON representation of `SwiftDocs`.
    public var description: String {
        return toJSON()
    }

}
