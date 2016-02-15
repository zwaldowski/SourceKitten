//
//  NSRegularExpression+SourceKitten.swift
//  SourceKitten
//
//  Created by Zachary Waldowski on 1/30/16.
//  Copyright © 2016 SourceKitten. All rights reserved.
//

import Foundation

struct MatchGroup: CollectionType, CustomStringConvertible, CustomReflectable {

    private let result: NSTextCheckingResult
    private let source: String

    private init(result: NSTextCheckingResult, within characters: String) {
        self.result = result
        self.source = characters
    }

    var range: Range<String.Index> {
        // From NSRegularExpression: "A result must have at least one range, but
        // may optionally have more (for example, to represent capture groups).
        // The range at index 0 always matches the range property."
        return result.range.sameRangeIn(source)!
    }

    private func substringForRange(range: NSRange) -> String? {
        return range.sameRangeIn(source).map { source[$0] }
    }

    var startIndex: Int {
        return 1
    }

    var endIndex: Int {
        return result.numberOfRanges
    }

    subscript(i: Int) -> String? {
        let range = result.rangeAtIndex(i)
        return substringForRange(range)
    }

    var ranges: LazyMapCollection<Range<Int>, Range<String.Index>?> {
        return indices.lazy.map {
            self.result.rangeAtIndex($0).sameRangeIn(self.source)
        }
    }
    
    var description: String {
        return substringForRange(result.range) ?? "<invalid>"
    }

    func customMirror() -> Mirror {
        return Mirror(self, children: [
            "range": String(range),
            "substring": source[range]
        ], displayStyle: .Struct)
    }

}

extension String {

    func match(regex: NSRegularExpression, options: NSMatchingOptions = []) -> MatchGroup? {
        return regex.firstMatchInString(self, options: [], range: .init(0 ..< utf16.count)).map {
            MatchGroup(result: $0, within: self)
        }
    }

    func matches(regex: NSRegularExpression, options: NSMatchingOptions = []) -> [MatchGroup] {
        return regex.matchesInString(self, options: [], range: .init(0 ..< utf16.count)).map {
            MatchGroup(result: $0, within: self)
        }
    }

}
