//
//  Text.swift
//  SourceKitten
//
//  Created by JP Simard on 10/27/15.
//  Copyright © 2015 SourceKitten. All rights reserved.
//

public enum Text {
    case Para(String, String?)
    case Verbatim(String)
}

// MARK: Equatable

public func == (lhs: Text, rhs: Text) -> Bool {
    switch (lhs, rhs) {
    case let (.Para(lText, lKind), .Para(rText, rKind)):
        return lText == rText && lKind == rKind
    case let (.Verbatim(lText), .Verbatim(rText)):
        return lText == rText
    default:
        return false
    }
}

extension Text: Equatable {}

// MARK: Serializable

extension Text: Serializable {

    func toOutput() -> Output {
        switch self {
        case .Para(let str, let kind):
            return .Object(["kind": kind ?? "", "Para": str])
        case .Verbatim(let str):
            return .Object(["kind": "", "Verbatim": str])
        }
    }

}
