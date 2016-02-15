//
//  SourceLocationNew.swift
//  SourceKitten
//
//  Created by Zachary Waldowski on 1/31/16.
//  Copyright © 2016 SourceKitten. All rights reserved.
//

public protocol SourceLocationNew: Comparable, CustomDebugStringConvertible, CustomReflectable {
    var filename: String? { get }
    var line: Int { get }
    var column: Int { get }
    var offset: Int { get }

    func filesEqual(other: Self) -> Bool
}

public func < <Loc: SourceLocationNew>(lhs: Loc, rhs: Loc) -> Bool {
    return lhs.filename < rhs.filename && lhs.offset < rhs.offset
}

public func <= <Loc: SourceLocationNew>(lhs: Loc, rhs: Loc) -> Bool {
    return lhs.filename <= rhs.filename && lhs.offset <= rhs.offset
}

public func >= <Loc: SourceLocationNew>(lhs: Loc, rhs: Loc) -> Bool {
    return lhs.filename >= rhs.filename && lhs.offset >= rhs.offset
}

public func > <Loc: SourceLocationNew>(lhs: Loc, rhs: Loc) -> Bool {
    return lhs.filename > rhs.filename && lhs.offset > rhs.offset
}

public func == <Loc: SourceLocationNew>(lhs: Loc, rhs: Loc) -> Bool {
    return lhs.filesEqual(rhs) &&
        lhs.line == rhs.line &&
        lhs.column == rhs.column &&
        lhs.offset == rhs.offset
}

extension SourceLocationNew {

    public func filesEqual(other: Self) -> Bool {
        return filename == other.filename
    }

    public var debugDescription: String {
        if let file = filename.flatMap({ NSURL(fileURLWithPath: $0, isDirectory: false) })?.lastPathComponent {
            return "\(file):\(line):\(column)"
        } else {
            return String(offset)
        }
    }

    public func customMirror() -> Mirror {
        if let filename = filename {
            return Mirror(self, children: [
                "filename": filename,
                "line": line,
                "column": column
            ], displayStyle: .Struct)
        } else {
            return Mirror(reflecting: offset)
        }
    }

}

extension IntervalType where Bound: SourceLocationNew {

    /// Returns `true` iff the `Interval` contains `x`.
    public func contains(x: Bound) -> Bool {
        guard start.filesEqual(x) else { return false }
        return x.offset >= start.offset && x.offset < end.offset
    }

    /// A textual representation of `self`.
    public var description: String {
        return "\(start.filename): \(start.offset) ..< \(end.offset)"
    }

    /// A textual representation of `self`, suitable for debugging.
    public var debugDescription: String {
        return "\(self.dynamicType)(\(String(reflecting: start)) ..< \(String(reflecting: end)))"
    }
    
}
