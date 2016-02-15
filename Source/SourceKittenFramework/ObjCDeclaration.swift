//
//  ObjCDeclaration.swift
//  SourceKitten
//
//  Created by Zachary Waldowski on 1/31/16.
//  Copyright © 2016 SourceKitten. All rights reserved.
//

public struct ObjCDeclaration: SourceDeclarationNew {

    private let cursor: CXCursor
    private unowned let translationUnit: ClangTranslationUnit

    init?(cursor: CXCursor, within translationUnit: ClangTranslationUnit) {
        guard cursor.shouldDocument() else { return nil }
        self.cursor = cursor
        self.translationUnit = translationUnit
    }

    public var kind: ObjCDeclarationKind {
        return cursor.objCKind()
    }

    public var location: ObjCLocation {
        return ObjCLocation(location: clang_getCursorLocation(cursor), within: translationUnit)
    }

    public var extent: ObjCSourceRange {
        return .init(range: clang_getCursorExtent(cursor), within: translationUnit)
    }

    public var accessibility: Void {
        return ()
    }

    public var name: String? {
        return cursor.name()
    }

    public var symbol: String? {
        return cursor.usr()
    }

    public var declaration: String? {
        return cursor.declaration()
    }

    public var documentation: Documentation {
        return Documentation(comment: cursor.parsedComment())
    }

    public var commentBody: String? {
        return cursor.commentBody()
    }

    public var children: [ObjCDeclaration] {
        return cursor.flatMap { [translationUnit] in
            ObjCDeclaration(cursor: $0, within: translationUnit)
        }.rejectPropertyMethods()
    }

    public var hashValue: Int {
        return Int(clang_hashCursor(cursor))
    }

}

public func == (lhs: ObjCDeclaration, rhs: ObjCDeclaration) -> Bool {
    return clang_equalCursors(lhs.cursor, rhs.cursor) != 0
}

private extension ObjCDeclaration {
    /// Returns the USR for the auto-generated getter for this property.
    ///
    /// - warning: can only be invoked if `type == .Property`.
    var getterUSR: String {
        return generateAccessorUSR(getter: true)
    }

    /// Returns the USR for the auto-generated setter for this property.
    ///
    /// - warning: can only be invoked if `type == .Property`.
    var setterUSR: String {
        return generateAccessorUSR(getter: false)
    }

    static let getterUSRRegex = try! NSRegularExpression(pattern: "getter\\s*=\\s*(\\w+)", options: [])
    static let setterUSRRegex = try! NSRegularExpression(pattern: "setter\\s*=\\s*(\\w+:)", options: [])

    private func generateAccessorUSR(getter getter: Bool) -> String {
        guard case .Property = kind else { preconditionFailure("Not a property") }
        guard let usr = symbol else { preconditionFailure("Couldn't extract USR") }
        guard let declaration = declaration else { preconditionFailure("Couldn't extract declaration") }
        
        let pyStartIndex = usr.rangeOfString("(py)")!.startIndex
        let usrPrefix = usr.substringToIndex(pyStartIndex)

        let regex = getter ? ObjCDeclaration.getterUSRRegex : ObjCDeclaration.setterUSRRegex
        if let match = declaration.match(regex)?[0] {
            return "\(usrPrefix)(im)\(match)"
        } else if getter {
            return usr.stringByReplacingOccurrencesOfString("(py)", withString: "(im)")
        } else { // setter
            let capitalFirstLetter = String(usr.characters[pyStartIndex.advancedBy(4)]).capitalizedString
            let restOfSetterName = usr.substringFromIndex(pyStartIndex.advancedBy(5))
            return "\(usrPrefix)(im)set\(capitalFirstLetter)\(restOfSetterName):"
        }
    }
}

private extension SequenceType where Generator.Element == ObjCDeclaration {
    /// Removes implicitly generated property getters & setters
    func rejectPropertyMethods() -> [ObjCDeclaration] {
        var usrs = Set<String>()
        for decl in self {
            guard case .Property = decl.kind else { continue }
            usrs.unionInPlace([decl.getterUSR, decl.setterUSR])
        }
        return filter { !usrs.contains($0.symbol!) }
    }
}

// MARK: - Serializable

extension ObjCDeclaration: Serializable {

    func toOutput() -> Output {
        var dict = [String: AnyObject]()

        func set(key: SwiftDocKey, _ value: AnyObject?) {
            if let value = value {
                dict[key.rawValue] = value
            }
        }

        func setA(key: SwiftDocKey, _ value: Output?) {
            guard case let .Array(array)? = value where !array.isEmpty else { return }
            dict[key.rawValue] = array
        }

        set(.Kind, kind.rawValue)
        set(.FilePath, location.filename)
        set(.DocFile, location.filename)
        set(.DocLine, location.line)
        set(.DocColumn, location.column)
        set(.Name, name)
        set(.USR, symbol)
        set(.ParsedDeclaration, declaration)
        set(.DocumentationComment, commentBody)
        set(.ParsedScopeStart, extent.start.line)
        set(.ParsedScopeEnd, extent.end.line)

        setA(.DocResultDiscussion, documentation.returnDiscussion.toOutput())
        setA(.DocParameters, documentation.parameters.toOutput())
        setA(.Substructure, children.toOutput())

        if commentBody != nil {
            set(.FullXMLDocs, "")
        }

        return .Object(dict)
    }

}


