//
//  SwiftCursorDocumentation.swift
//  SourceKitten
//
//  Created by Zachary Waldowski on 2/20/16.
//  Copyright © 2016 SourceKitten. All rights reserved.
//

import SWXMLHash

struct SwiftCursorDocumentation {
    let location: SwiftLocation
    let name: String?
    let symbol: String?
    let declaration: String?
    let documentation: Documentation

    private static func childrenAsText(indexer: XMLIndexer) -> [Text] {
        return indexer.children.map {
            .Para($0.element?.text ?? "", nil)
        }
    }

    init(declaration: SwiftDeclaration) {
        self.location = declaration.location
        self.name = declaration.name
        self.symbol = declaration.symbol
        self.declaration = declaration.declaration
        self.documentation = declaration.documentation
    }

    init?(XMLDocs xmlDocs: String, at offset: Int64 = 0) {
        let cleanXMLDocs = xmlDocs.stringByReplacingOccurrencesOfString("<rawHTML>", withString: "")
            .stringByReplacingOccurrencesOfString("</rawHTML>", withString: "")
            .stringByReplacingOccurrencesOfString("<codeVoice>", withString: "`")
            .stringByReplacingOccurrencesOfString("</codeVoice>", withString: "`")
        guard let rootXML = SWXMLHash.parse(cleanXMLDocs).children.first else { return nil }

        guard let file = rootXML.element?.attributes["file"],
            line = rootXML.element?.attributes["line"].flatMap({ Int($0) }),
            column = rootXML.element?.attributes["column"].flatMap({ Int($0) }) else {
                return nil
        }

        let parameters = rootXML["Parameters"].children.flatMap { param -> Parameter in
            let name = param["Name"].element?.text ?? ""
            let text = param["Discussion"].flatMap(SwiftCursorDocumentation.childrenAsText)
            return Parameter(name: name, discussion: text)
        }
        let returnDiscussion = rootXML["ResultDiscussion"].flatMap(SwiftCursorDocumentation.childrenAsText)

        self.location = SwiftLocation(filename: file, line: line, column: column, offset: numericCast(offset))
        self.name = rootXML["Name"].element?.text
        self.symbol = rootXML["USR"].element?.text
        self.declaration = rootXML["Declaration"].element?.text
        self.documentation = .init(parameters: parameters, returnDiscussion: returnDiscussion)
    }
}
