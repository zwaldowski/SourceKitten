//
//  Parameter.swift
//  SourceKitten
//
//  Created by JP Simard on 10/27/15.
//  Copyright © 2015 SourceKitten. All rights reserved.
//

#if SWIFT_PACKAGE
import Clang_C
#endif

public struct Parameter {
    let name: String
    let discussion: [Text]

    init(comment: CXComment) {
        name = comment.paramName() ?? "<none>"
        discussion = comment.paragraph().paragraphToString()
    }
}

// MARK: Equatable

extension Parameter: Equatable {}

public func == (lhs: Parameter, rhs: Parameter) -> Bool {
    return lhs.name == rhs.name && lhs.discussion == rhs.discussion
}

// MARK: Serializable

extension Parameter: Serializable {
    func toOutput() -> Output {
        return .Object([
            "name": name,
            "discussion": discussion.toObject()
        ])
    }
}
