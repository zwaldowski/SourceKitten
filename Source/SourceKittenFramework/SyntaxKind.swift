//
//  SyntaxKind.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-03.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

/// Syntax kind values.
/// https://github.com/apple/swift/blob/master/tools/SourceKit/lib/SwiftLang/SwiftLangSupport.cpp
public enum SyntaxKind: UID {
    case Unknown             = "unknown"
    /// `argument`.
    case Argument            = "source.lang.swift.syntaxtype.argument"
    /// `parameter`.
    case Parameter           = "source.lang.swift.syntaxtype.parameter"
    /// `keyword`.
    case Keyword             = "source.lang.swift.syntaxtype.keyword"
    /// `identifier`.
    case Identifier          = "source.lang.swift.syntaxtype.identifier"
    /// `typeidentifier`.
    case TypeIdentifier      = "source.lang.swift.syntaxtype.typeidentifier"
    /// `buildconfig.keyword`.
    case BuildConfigKeyword  = "source.lang.swift.syntaxtype.buildconfig.keyword"
    /// `buildconfig.id`.
    case BuildConfigId       = "source.lang.swift.syntaxtype.buildconfig.id"
    /// `attribute.id`.
    case AttributeId         = "source.lang.swift.syntaxtype.attribute.id"
    /// `attribute.builtin`.
    case AttributeBuiltin    = "source.lang.swift.syntaxtype.attribute.builtin"
    /// `number`.
    case Number              = "source.lang.swift.syntaxtype.number"
    /// `string`.
    case String              = "source.lang.swift.syntaxtype.string"
    /// `string_interpolation_anchor`.
    case StringInterpolation = "source.lang.swift.syntaxtype.string_interpolation_anchor"
    /// `comment`.
    case Comment             = "source.lang.swift.syntaxtype.comment"
    /// `doccomment`.
    case DocComment          = "source.lang.swift.syntaxtype.doccomment"
    /// `doccomment.field`.
    case DocCommentField     = "source.lang.swift.syntaxtype.doccomment.field"
    /// `comment.mark`.
    case CommentMarker       = "source.lang.swift.syntaxtype.comment.mark"
    /// `comment.url`.
    case CommentURL          = "source.lang.swift.syntaxtype.comment.url"
    /// `placeholder`.
    case Placeholder         = "source.lang.swift.syntaxtype.placeholder"
    /// `objectliteral`
    case ObjectLiteral       = "source.lang.swift.syntaxtype.objectliteral"

    /// Returns the valid documentation comment syntax kinds.
    internal static var docComments: Set<SyntaxKind> {
        return [CommentURL, DocComment, DocCommentField]
    }
}

public enum SyntaxKindOld: String {
    /// `argument`.
    case Argument = "source.lang.swift.syntaxtype.argument"
    /// `attribute.builtin`.
    case AttributeBuiltin = "source.lang.swift.syntaxtype.attribute.builtin"
    /// `attribute.id`.
    case AttributeID = "source.lang.swift.syntaxtype.attribute.id"
    /// `buildconfig.id`.
    case BuildconfigID = "source.lang.swift.syntaxtype.buildconfig.id"
    /// `buildconfig.keyword`.
    case BuildconfigKeyword = "source.lang.swift.syntaxtype.buildconfig.keyword"
    /// `comment`.
    case Comment = "source.lang.swift.syntaxtype.comment"
    /// `comment.mark`.
    case CommentMark = "source.lang.swift.syntaxtype.comment.mark"
    /// `comment.url`.
    case CommentURL = "source.lang.swift.syntaxtype.comment.url"
    /// `doccomment`.
    case DocComment = "source.lang.swift.syntaxtype.doccomment"
    /// `doccomment.field`.
    case DocCommentField = "source.lang.swift.syntaxtype.doccomment.field"
    /// `identifier`.
    case Identifier = "source.lang.swift.syntaxtype.identifier"
    /// `keyword`.
    case Keyword = "source.lang.swift.syntaxtype.keyword"
    /// `number`.
    case Number = "source.lang.swift.syntaxtype.number"
    /// `objectliteral`
    case ObjectLiteral = "source.lang.swift.syntaxtype.objectliteral"
    /// `parameter`.
    case Parameter = "source.lang.swift.syntaxtype.parameter"
    /// `placeholder`.
    case Placeholder = "source.lang.swift.syntaxtype.placeholder"
    /// `string`.
    case String = "source.lang.swift.syntaxtype.string"
    /// `string_interpolation_anchor`.
    case StringInterpolationAnchor = "source.lang.swift.syntaxtype.string_interpolation_anchor"
    /// `typeidentifier`.
    case Typeidentifier = "source.lang.swift.syntaxtype.typeidentifier"

    /// Returns the valid documentation comment syntax kinds.
    internal static func docComments() -> [SyntaxKindOld] {
        return [CommentURL, DocComment, DocCommentField]
    }
}
