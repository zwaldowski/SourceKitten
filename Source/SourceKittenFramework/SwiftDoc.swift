//
//  SwiftDoc.swift
//  SourceKitten
//
//  Created by Zachary Waldowski on 1/18/16.
//  Copyright © 2016 SourceKitten. All rights reserved.
//

import SWXMLHash

struct SwiftDoc {

    struct Parameter {
        let name: String
        let discussion: [[String: String]]
    }

    let kind: String?
    let file: String?
    let line: Int64?
    let column: Int64?
    let name: String?
    let USR: String?
    let declaration: String?
    let parameters: [Parameter]?
    let discussion: [[String: String]]?
    let resultDiscussion: [[String: String]]?

    init?(xml xmlDocs: String) {
        let cleanXMLDocs = xmlDocs.stringByReplacingOccurrencesOfString("<rawHTML>", withString: "")
            .stringByReplacingOccurrencesOfString("</rawHTML>", withString: "")
            .stringByReplacingOccurrencesOfString("<codeVoice>", withString: "`")
            .stringByReplacingOccurrencesOfString("</codeVoice>", withString: "`")
        guard let rootXML = SWXMLHash.parse(cleanXMLDocs).children.first else {
            return nil
        }
        kind = rootXML.element?.name
        file = rootXML.element?.attributes["file"]
        line = rootXML.element?.attributes["line"].flatMap { Int64($0) }
        column = rootXML.element?.attributes["column"].flatMap { Int64($0) }
        name = rootXML["Name"].element?.text
        USR = rootXML["USR"].element?.text
        declaration = rootXML["Declaration"].element?.text
        let parameters = rootXML["Parameters"].children
        if parameters.isEmpty {
            self.parameters = nil
        } else {
            self.parameters = rootXML["Parameters"].children.map {
                Parameter(name: $0["Name"].element?.text ?? "",
                    discussion: childrenAsArray($0["Discussion"]) ?? [])
            }
        }
        discussion = childrenAsArray(rootXML["Discussion"])
        resultDiscussion = childrenAsArray(rootXML["ResultDiscussion"])
    }
    
}

/**
 Returns an `Array` of `[String: String]` items from `indexer` children, if any.

 - parameter indexer: `XMLIndexer` to traverse.
 */
private func childrenAsArray(indexer: XMLIndexer) -> [[String: String]]? {
    let children = indexer.children
    guard !children.isEmpty else {
        return nil
    }
    return children.lazy.flatMap { $0.element }.map {
        [$0.name: $0.text ?? ""]
    }
}
