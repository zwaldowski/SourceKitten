//
//  SwiftLocation.swift
//  SourceKitten
//
//  Created by Zachary Waldowski on 1/31/16.
//  Copyright © 2016 SourceKitten. All rights reserved.
//

public typealias SwiftRange = HalfOpenInterval<SwiftLocation>

public struct SwiftLocation: SourceLocationNew {
    public let filename: String?
    public let line: Int
    public let column: Int
    public let offset: Int
}

extension SwiftLocation {
    init() {
        self.filename = nil
        self.line = 0
        self.column = 0
        self.offset = 0
    }
}
