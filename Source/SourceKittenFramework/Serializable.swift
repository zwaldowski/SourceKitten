//
//  Serializable.swift
//  SourceKitten
//
//  Created by Zachary Waldowski on 2/14/16.
//  Copyright © 2015 SourceKitten. All rights reserved.
//

/// SourceKit types may be rendered in one of two ways for serialization:
/// objects or dictionaries.
enum Output {
    case Object([String: AnyObject])
    case Array([AnyObject])

    private var objectValue: AnyObject {
        switch self {
        case let .Object(dict):
            return dict
        case let .Array(array):
            return array
        }
    }
}

/// A type which may be serialized.
protocol Serializable {

    /// A serialized representation of `self`.
    func toOutput() -> Output

}

extension Serializable {

    /// A serialized representation of `self` as a Cocoa property list type.
    func toObject() -> AnyObject {
        return toOutput().objectValue
    }

    /// A serialized representation of `self` as a JSON string.
    func toJSON() -> String {
        do {
            let prettyJSONData = try NSJSONSerialization.dataWithJSONObject(toObject(), options: .PrettyPrinted)
            if let jsonString = NSString(data: prettyJSONData, encoding: NSUTF8StringEncoding) as? String {
                return jsonString
            }
        } catch {}
        return ""
    }
    
}

extension SequenceType where Generator.Element: Serializable {

    /// Serialize each member of the collection.
    func toOutput() -> Output {
        return .Array(map {
            $0.toOutput().objectValue
        })
    }

    /// Serialize each member of the collection as a Cocoa property list type.
    func toObject() -> AnyObject {
        return toOutput().objectValue
    }

}
