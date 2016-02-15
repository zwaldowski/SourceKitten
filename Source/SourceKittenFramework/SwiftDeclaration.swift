//
//  SwiftDeclaration.swift
//  SourceKitten
//
//  Created by Zachary Waldowski on 1/31/16.
//  Copyright © 2016 SourceKitten. All rights reserved.
//

public enum SwiftAccessibility: String {
    case Internal = "source.lang.swift.accessibility.internal"
    case Private = "source.lang.swift.accessibility.private"
    case Public = "source.lang.swift.accessibility.public"
}

public struct SwiftDeclaration: SourceDeclarationNew {
    public let kind: SwiftDeclarationKind
    public let location: SwiftLocation
    public internal(set) var extent = SwiftLocation() ..< SwiftLocation()
    public internal(set) var accessibility = SwiftAccessibility.Internal
    public internal(set) var name: String?
    public internal(set) var symbol: String?
    public internal(set) var declaration: String?
    public internal(set) var documentation = Documentation()
    public internal(set) var commentBody: String?
    public internal(set) var children: [SwiftDeclaration] = []

    internal var nameExtent: SwiftRange?
    internal var bodyExtent: SwiftRange?

    init(kind: SwiftDeclarationKind, location: SwiftLocation) {
        self.kind = kind
        self.location = location
    }
}

public func == (lhs: SwiftDeclaration, rhs: SwiftDeclaration) -> Bool {
    return lhs.kind == rhs.kind && lhs.symbol == rhs.symbol && lhs.location == rhs.location
}

// MARK: - Serializable

extension SwiftDeclaration: Serializable {

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
        set(.ParsedScopeStart, extent.start.line)
        set(.ParsedScopeEnd, extent.end.line)
        set(.Accessibility, accessibility.rawValue)
        set(.Name, name)
        set(.DocName, name)
        set(.USR, symbol)
        set(.ParsedDeclaration, declaration)
        setA(.DocParameters, documentation.parameters.toOutput())
        setA(.DocResultDiscussion, documentation.returnDiscussion.toOutput())
        set(.DocumentationComment, commentBody)
        setA(.Substructure, children.toOutput())
        set(.FullXMLDocs, commentBody.map { _ in "" })

        let nameOffset = nameExtent?.start.offset
        let nameLength = nameExtent.map { $0.end.offset - $0.start.offset }
        set(.Offset, nameOffset)
        set(.Length, nameLength)
        set(.NameOffset, nameOffset)
        set(.NameLength, nameLength)

        set(.BodyOffset, bodyExtent?.start.offset)
        set(.BodyLength, bodyExtent.map { $0.end.offset - $0.start.offset })

        return .Object(dict)
    }

}
