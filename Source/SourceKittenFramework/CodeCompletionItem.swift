//
//  CodeCompletionItem.swift
//  SourceKitten
//
//  Created by JP Simard on 9/4/15.
//  Copyright © 2015 SourceKitten. All rights reserved.
//

extension Dictionary {
    private mutating func addIfNotNil(key: Key, _ value: Value?) {
        if let value = value {
            self[key] = value
        }
    }
}

public struct CodeCompletionItem: CustomStringConvertible {

    public enum Context: UID {
        case None = "source.codecompletion.context.none"
        case ExpressionSpecific = "source.codecompletion.context.exprspecific"
        case Local = "source.codecompletion.context.local"
        case CurrentNominal = "source.codecompletion.context.thisclass"
        case Super = "source.codecompletion.context.superclass"
        case OutsideNominal = "source.codecompletion.context.otherclass"
        case CurrentModule = "source.codecompletion.context.thismodule"
        case OtherModule = "source.codecompletion.context.othermodule"
    }

    public let kind: SwiftDeclarationKind
    public let context: Context
    public let name: String?
    public let descriptionKey: String?
    public let sourcetext: String?
    public let typeName: String?
    public let moduleName: String?
    public let docBrief: String?
    public let associatedUSRs: String?

    /// Dictionary representation of CodeCompletionItem. Useful for NSJSONSerialization.
    public var dictionaryValue: [String: AnyObject] {
        var dict = [
            "kind": String(kind.rawValue),
            "context": String(context.rawValue),
        ]
        dict.addIfNotNil("name", name)
        dict.addIfNotNil("descriptionKey", descriptionKey)
        dict.addIfNotNil("sourcetext", sourcetext)
        dict.addIfNotNil("typeName", typeName)
        dict.addIfNotNil("moduleName", moduleName)
        dict.addIfNotNil("docBrief", docBrief)
        dict.addIfNotNil("associatedUSRs", associatedUSRs)
        return dict
    }

    public var description: String {
        return toJSON(dictionaryValue)
    }
}

extension CodeCompletionItem: SourceKitResponseConvertible {

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

    public init(sourceKitResponse response: Response) throws {
        let dict = try response.value(of: Response.Dictionary.self)
        let kind = try dict.uidFor(ResponseKey.Kind, of: SwiftDeclarationKind.self)
        let context = try dict.uidFor(ResponseKey.Context, of: Context.self)
        self.init(kind: kind, context: context,
            name: try? dict.valueFor(ResponseKey.Name),
            descriptionKey: try? dict.valueFor(ResponseKey.Description),
            sourcetext: try? dict.valueFor(ResponseKey.SourceText),
            typeName: try? dict.valueFor(ResponseKey.TypeName),
            moduleName: try? dict.valueFor(ResponseKey.ModuleName),
            docBrief: try? dict.valueFor(ResponseKey.DocBrief),
            associatedUSRs: try? dict.valueFor(ResponseKey.AssociatedUSRs))

    }

    public static func parseResponse(response: Response) -> [CodeCompletionItem] {
        do {
            let dict = try response.value(of: Response.Dictionary.self)
            let array = try dict.valueFor(ResponseKey.Results, of: Response.Array.self)
            return try array.map(CodeCompletionItem.init)
        } catch {
            return []
        }
    }

}
