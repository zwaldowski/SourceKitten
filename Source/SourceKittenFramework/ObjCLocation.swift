//
//  ObjCLocation.swift
//  SourceKitten
//
//  Created by Zachary Waldowski on 1/31/16.
//  Copyright © 2016 SourceKitten. All rights reserved.
//

public struct ObjCLocation: SourceLocationNew {

    private let location: CXSourceLocation
    private unowned let translationUnit: ClangTranslationUnit

    init(location: CXSourceLocation, within translationUnit: ClangTranslationUnit) {
        self.location = location
        self.translationUnit = translationUnit
    }

    private var file: CXFile {
        var cxfile: CXFile = nil
        clang_getSpellingLocation(location, &cxfile, nil, nil, nil)
        return cxfile
    }

    public var filename: String? {
        return clang_getFileName(file).str()
    }

    public var line: Int {
        var line: UInt32 = 0
        clang_getSpellingLocation(location, nil, &line, nil, nil)
        return numericCast(line)
    }

    public var column: Int {
        var column: UInt32 = 0
        clang_getSpellingLocation(location, nil, nil, &column, nil)
        return numericCast(column)
    }

    public var offset: Int {
        var offset: UInt32 = 0
        clang_getSpellingLocation(location, nil, nil, nil, &offset)
        return numericCast(offset)
    }

    public func filesEqual(other: ObjCLocation) -> Bool {
        return clang_File_isEqual(file, other.file) != 0
    }

}

public struct ObjCSourceRange: IntervalType {

    private let range: CXSourceRange
    private unowned let translationUnit: ClangTranslationUnit

    private init(nullWithin translationUnit: ClangTranslationUnit) {
        self.range = clang_getNullRange()
        self.translationUnit = translationUnit
    }

    private init(start: ObjCLocation, end: ObjCLocation) {
        self.range = clang_getRange(start.location, end.location)
        self.translationUnit = start.translationUnit
    }

    init(range: CXSourceRange, within translationUnit: ClangTranslationUnit) {
        self.range = range
        self.translationUnit = translationUnit
    }

    /// Returns `intervalToClamp` clamped to `self`.
    ///
    /// The bounds of the result, even if it is empty, are always limited to the bounds of
    /// `self`.
    public func clamp(other: ObjCSourceRange) -> ObjCSourceRange {
        guard start.filesEqual(other.start) else {
            return .init(nullWithin: translationUnit)
        }

        return .init(start: start > other.start ? start
            : end < other.start ? end
            : other.start, end: end < other.end ? end
            : start > other.end ? start
            : other.end)
    }

    /// `true` iff `self` is empty.
    public var isEmpty: Bool {
        return clang_Range_isNull(range) != 0 || start == end
    }

    /// The `Interval`'s lower bound.
    public var start: ObjCLocation {
        return .init(location: clang_getRangeStart(range), within: translationUnit)
    }

    /// The `Interval`'s upper bound.
    public var end: ObjCLocation {
        return .init(location: clang_getRangeEnd(range), within: translationUnit)
    }

}

/// Forms a half-open range that contains `start`, but not `end`.
///
/// - requires: `start` and `end` have the same `filename`; `start <= end`.
public func ..< (start: ObjCLocation, end: ObjCLocation) -> ObjCSourceRange {
    return .init(start: start, end: end)
}

/// Return true if `lhs` refers to the same location in the same file as `rhs`.
public func ==(lhs: ObjCLocation, rhs: ObjCLocation) -> Bool {
    return clang_equalLocations(lhs.location, rhs.location) != 0
}

/// Return true if `lhs` refers to the same range in the same files as `rhs`.
public func ==(lhs: ObjCSourceRange, rhs: ObjCSourceRange) -> Bool {
    return clang_equalRanges(lhs.range, rhs.range) != 0
}

