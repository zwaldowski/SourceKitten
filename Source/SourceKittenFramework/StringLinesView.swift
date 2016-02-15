//
//  StringLinesView.swift
//  SourceKitten
//
//  Created by Zachary Waldowski on 2/20/16.
//  Copyright © 2016 SourceKitten. All rights reserved.
//

extension String {

    struct LinesView {
        private let source: String

        private init(_ source: String) {
            self.source = source
        }

        struct Index {
            private let source: String
            private let location: String.Index

            private init(_ source: String, location: String.Index) {
                self.source = source
                self.location = location
            }
        }
    }

    typealias LinesIndex = LinesView.Index

    var lines: LinesView {
        return .init(self)
    }

}


extension String.LinesView: CollectionType {

    var startIndex: Index {
        return .init(source, location: source.startIndex)
    }

    var endIndex: Index {
        return .init(source, location: source.endIndex)
    }

    subscript(i: Index) -> String {
        guard i.location != source.endIndex else {
            return ""
        }
        var start = source.startIndex
        var end = source.endIndex
        source.getLineStart(&start, end: nil, contentsEnd: &end, forRange: i.location ..< i.location)
        return source[start ..< end]
    }

}

extension String.LinesView.Index: BidirectionalIndexType {

    func predecessor() -> String.LinesView.Index {
        guard location != source.startIndex else { return self }

        var next = location.predecessor()
        source.getLineStart(&next, end: nil, contentsEnd: nil, forRange: next ..< next)
        return .init(source, location: next)
    }

    func successor() -> String.LinesView.Index {
        guard location != source.endIndex else { return self }

        var next = location
        source.getLineStart(nil, end: &next, contentsEnd: nil, forRange: next ..< next)
        return .init(source, location: next)
    }

}

func == (lhs: String.LinesView.Index, rhs: String.LinesView.Index) -> Bool {
    return lhs.location == rhs.location
}
