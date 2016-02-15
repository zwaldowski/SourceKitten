//
//  NSRange+SourceKitten.swift
//  SourceKitten
//
//  Created by Zachary Waldowski on 1/30/16.
//  Copyright © 2016 SourceKitten. All rights reserved.
//

import Foundation

extension NSRange {

    init(_ range: Range<String.Index>, within characters: String) {
        let u16Start = range.startIndex.samePositionIn(characters.utf16)
        let u16End = range.endIndex.samePositionIn(characters.utf16)
        self.init(u16Start ..< u16End, within: characters)
    }

    init(_ range: Range<String.UTF16View.Index>, within characters: String) {
        location = characters.utf16.startIndex.distanceTo(range.startIndex)
        length = range.count
    }

    func sameRangeIn(characters: String) -> Range<String.Index>? {
        guard location != NSNotFound else { return nil }

        let utfStart = characters.utf16.startIndex.advancedBy(location, limit: characters.utf16.endIndex)
        guard length == 0 || utfStart != characters.utf16.endIndex else { return nil }
        let utfEnd = utfStart.advancedBy(length, limit: characters.utf16.endIndex)

        guard let start = utfStart.samePositionIn(characters), end = utfEnd.samePositionIn(characters) else { return nil }
        return start ..< end
    }
    
}
