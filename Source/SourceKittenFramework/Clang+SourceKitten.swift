//
//  Clang+SourceKitten.swift
//  SourceKitten
//
//  Created by Thomas Goyne on 9/17/15.
//  Copyright © 2015 SourceKitten. All rights reserved.
//

class ClangIndex {
    private let cx = clang_createIndex(0, 1)

    func open(file file: String, args: [UnsafePointer<Int8>]) -> CXTranslationUnit {
        return clang_createTranslationUnitFromSourceFile(cx,
            file,
            Int32(args.count),
            args,
            0,
            nil)
    }

    deinit {
        clang_disposeIndex(cx)
    }
}

enum CommentKind: UInt32 {
    case Null = 0
    case Text = 1
    case InlineCommand = 2
    case HTMLStartTag = 3
    case HTMLEndTag = 4
    case Paragraph = 5
    case BlockCommand = 6
    case ParamCommand = 7
    case TParamCommand = 8
    case VerbatimBlockCommand = 9
    case VerbatimBlockLine = 10
    case VerbatimLine = 11
    case FullComment = 12
}

extension CXString: CustomStringConvertible {
    func bridge() -> String? {
        let str = String.fromCString(clang_getCString(self))
        clang_disposeString(self)
        return str
    }

    public var description: String {
        return String.fromCString(clang_getCString(self)) ?? "<null>"
    }
}

extension CXTranslationUnit {
    func cursor() -> CXCursor {
        return clang_getTranslationUnitCursor(self)
    }

    func visit(block: ((CXCursor, CXCursor) -> CXChildVisitResult)) {
        self.cursor().visit(block)
    }
}

extension CXCursor {
    func location() -> SourceLocation {
        var cxfile = CXFile()
        var line: UInt32 = 0
        var column: UInt32 = 0
        var offset: UInt32 = 0
        clang_getSpellingLocation(clang_getCursorLocation(self), &cxfile, &line, &column, &offset)
        return SourceLocation(file: clang_getFileName(cxfile).bridge() ?? "<none>",
            line: line, column: column, offset: offset)
    }

    func name() -> String {
        return clang_getCursorSpelling(self).bridge()!
    }

    func type() -> CXType {
        return clang_getCursorType(self)
    }

    func usr() -> String? {
        return clang_getCursorUSR(self).bridge()
    }

    func text() -> String {
        // Tokenize the string, then reassemble the tokens back into one string
        // This is kinda wtf but there's no way to get the raw string...
        let range = clang_getCursorExtent(self)
        var tokens = UnsafeMutablePointer<CXToken>()
        var count = UInt32(0)
        clang_tokenize(self.translationUnit(), range, &tokens, &count)

        func needsWhitespace(kind: CXTokenKind) -> Bool {
            return kind == CXToken_Identifier || kind == CXToken_Keyword
        }

        var str = ""
        var prevWasIdentifier = false
        for i in 0..<count {
            let type = clang_getTokenKind(tokens[Int(i)])
            if type == CXToken_Comment {
                break
            }

            if let s = tokens[Int(i)].str(self.translationUnit()) {
                if prevWasIdentifier && needsWhitespace(type) {
                    str += " "
                }
                str += s
                prevWasIdentifier = needsWhitespace(type)
            }
        }

        clang_disposeTokens(self.translationUnit(), tokens, count)
        return str
    }

    func translationUnit() -> CXTranslationUnit {
        return clang_Cursor_getTranslationUnit(self)
    }

    func visit(block: CXCursorVisitorBlock) {
        clang_visitChildrenWithBlock(self, block)
    }

    func parsedComment() -> CXComment {
        return clang_Cursor_getParsedComment(self)
    }

    func rawComment() -> String? {
        return clang_Cursor_getRawCommentText(self).bridge()
    }

    func flatMap<T>(block: (CXCursor) -> T?) -> [T] {
        var ret = [T]()
        visit() { cursor, _ in
            if let val = block(cursor) {
                ret.append(val)
            }
            return CXChildVisit_Continue
        }
        return ret
    }
}

extension CXToken {
    func str(tu: CXTranslationUnit) -> String? {
        return clang_getTokenSpelling(tu, self).bridge()
    }
}

extension CXType {
    func name() -> String? {
        return clang_getTypeSpelling(self).bridge()
    }
}

extension CXComment: SequenceType {
    func paramName() -> String? {
        guard self.kind() == .ParamCommand else { return nil }
        return clang_ParamCommandComment_getParamName(self).bridge()
    }

    func paragraph() -> CXComment {
        return clang_BlockCommandComment_getParagraph(self)
    }

    public func generate() -> AnyGenerator<CXComment> {
        var i: UInt32 = 0
        let count = clang_Comment_getNumChildren(self)
        return anyGenerator {
            guard i < count else { return nil }
            let ret = clang_Comment_getChild(self, i)
            ++i
            return ret
        }
    }

    func paragraphToString(kind: String? = nil) -> [Text] {
        if self.kind() == .VerbatimLine {
            let command = clang_BlockCommandComment_getCommandName(self).bridge() ?? ""
            return [.Verbatim("@" + command + clang_VerbatimLineComment_getText(self).bridge()!)]
        }
        if self.kind() == .BlockCommand  {
            var ret = [Text]()
            for child in self {
                ret += child.paragraphToString()
            }
            return ret
        }

        guard self.kind() == .Paragraph else {
            print("not a paragraph: \(self.kind())")
            return []
        }

        var ret = [String]()
        var indented = true
        var command = false
        for child in self {
            if child.isWhitespace() {
                continue
            }

            if let text = clang_TextComment_getText(child).bridge() {
                if command {
                    let last = ret[ret.count - 1]
                    ret[ret.count - 1] = last + text
                    command = false
                }
                else {
                    indented = indented && text.hasPrefix("   ")
                    ret.append(text.stringByRemovingCommonLeadingWhitespaceFromLines())
                }
            }
            else if child.kind() == .InlineCommand {
                // @autoreleasepool etc. get parsed as commands when not in code blocks
                ret.append("@" + clang_InlineCommandComment_getCommandName(child).bridge()!)
                command = true
            }
            else {
                print("not text: \(child.kind())")
            }
        }

        if ret.isEmpty {
            return []
        }

        if indented {
            return [.Verbatim(ret.joinWithSeparator("\n"))]
        }
        else {
            return [.Para(ret.joinWithSeparator("\n"), kind)]
        }
    }

    func kind() -> CommentKind {
        return CommentKind(rawValue: clang_Comment_getKind(self).rawValue)!
    }

    func commandName() -> String? {
        return clang_BlockCommandComment_getCommandName(self).bridge()
    }

    func count() -> UInt32 {
        return clang_Comment_getNumChildren(self)
    }

    func isWhitespace() -> Bool {
        return clang_Comment_isWhitespace(self) != 0
    }

    subscript(idx: UInt32) -> CXComment {
        return clang_Comment_getChild(self, idx)
    }
}
