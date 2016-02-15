//
//  OffsetMap.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-05.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

/// Type that maps potentially documented declaration offsets to its closest parent offset.
typealias OffsetMap = [Int: Int]

/// File methods to generate and manipulate OffsetMap's.
extension File {
    /**
    Creates an OffsetMap containing offset locations at which there are declarations that likely
    have documentation comments, but haven't been documented by the parser yet.

    - parameter documentedTokenOffsets: Offsets where there are declarations that likely
                                        have documentation comments.
    - parameter declarations:           List of declarationsto check for which offsets are
                                        already documented.
    */
    func generateOffsetMap(documentedTokenOffsets: [Int], declarations: [SwiftDeclaration]) -> OffsetMap {
        var offsetMap = OffsetMap()
        for offset in documentedTokenOffsets {
            offsetMap[offset] = 0
        }

        mapOffsetsFrom(declarations, within: &offsetMap)

        for alreadyDocumentedPair in offsetMap.lazy.filter({ $0.0 == $0.1 }) {
            offsetMap.removeValueForKey(alreadyDocumentedPair.0)
        }
        return offsetMap
    }

    /**
    Appends offsets by matching all offsets in the offsetMap parameter's keys
    to its nearest, currently documented parent offset.

    - parameter declarations: A list of already documented declarations.
    - parameter offsetMap:  Dictionary mapping potentially documented offsets to its nearest parent
                            offset.
    */
    private func mapOffsetsFrom(declarations: [SwiftDeclaration], inout within offsetMap: OffsetMap) {
        for decl in declarations {
            // Only map if we're in the correct file
            if decl.shouldTreatSameAsSameFile(self), let range = decl.codeByteRange {
                // TODO in 2.2: use Range.contains or case syntax
                for offset in offsetMap.keys where range ~= offset {
                    offsetMap[offset] = range.startIndex
                }
            }

            // Recurse!
            mapOffsetsFrom(decl.children, within: &offsetMap)
        }
    }
}

private extension SwiftDeclaration {

    var codeByteRange: Range<Int>? {
        guard let rangeStart = nameExtent?.start.offset, rangeEnd = bodyExtent?.end.offset else {
            return nil
        }
        return rangeStart ..< rangeEnd
    }

}
