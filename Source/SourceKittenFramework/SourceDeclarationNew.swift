//
//  SourceDeclarationNew.swift
//  SourceKitten
//
//  Created by Zachary Waldowski on 1/31/16.
//  Copyright © 2016 SourceKitten. All rights reserved.
//

public protocol DeclarationKind: RawRepresentable {}

public protocol SourceDeclarationNew: Equatable {
    typealias Kind: DeclarationKind
    typealias Location: SourceLocationNew = SourceLocation
    typealias Extent: IntervalType = HalfOpenInterval<Location>
    typealias Accessibility = Void

    var kind: Kind { get }
    var location: Location { get }
    var extent: Extent { get }
    var accessibility: Accessibility { get }
    var name: String? { get }
    var symbol: String? { get }
    var declaration: String? { get }
    var documentation: Documentation { get }
    var commentBody: String? { get }
    var children: [Self] { get }
}
