//
//  SourceKitTests.swift
//  SourceKitten
//
//  Created by JP Simard on 7/15/15.
//  Copyright © 2015 SourceKitten. All rights reserved.
//

import SourceKittenFramework
import XCTest

private func run(executable: String, arguments: [String]) -> String? {
    let task = NSTask()
    task.launchPath = executable
    task.arguments = arguments

    let pipe = NSPipe()
    task.standardOutput = pipe

    task.launch()

    let file = pipe.fileHandleForReading
    let output = NSString(data: file.readDataToEndOfFile(), encoding: NSUTF8StringEncoding)
    file.closeFile()
    return output as String?
}

private func sourcekitStringsStartingWith(pattern: String) -> Set<String> {
    var arguments = ["-f", "swiftc"]
    if let toolchain = NSProcessInfo.processInfo().environment["XCODE_DEFAULT_TOOLCHAIN_OVERRIDE"] {
        arguments += [ "--toolchain", toolchain ]
    }
    let sourceKitServicePath = (((run("/usr/bin/xcrun", arguments: arguments)! as NSString)
        .stringByDeletingLastPathComponent as NSString)
        .stringByDeletingLastPathComponent as NSString)
        .stringByAppendingPathComponent("lib/sourcekitd.framework/XPCServices/SourceKitService.xpc/Contents/MacOS/SourceKitService")
    let strings = run("/usr/bin/strings", arguments: [sourceKitServicePath])
    return Set(strings!.componentsSeparatedByString("\n").filter { string in
        return string.rangeOfString(pattern)?.startIndex == string.startIndex
    })
}

class SourceKitTests: XCTestCase {

    func testSyntaxKinds() {
        let expected: [SyntaxKind] = [
            .Argument,
            .Parameter,
            .Keyword,
            .Identifier,
            .TypeIdentifier,
            .BuildConfigKeyword,
            .BuildConfigId,
            .AttributeId,
            .AttributeBuiltin,
            .Number,
            .String,
            .StringInterpolation,
            .Comment,
            .DocComment,
            .DocCommentField,
            .CommentMarker,
            .CommentURL,
            .Placeholder,
            .ObjectLiteral,
        ]
        // SourceKit occasionally builds these through interpolation, so check prefixes only.
        var actual = sourcekitStringsStartingWith("source.lang.swift.syntaxtype.")
        for string in expected.lazy.map({ String($0.rawValue) }) {
            if actual.remove(string) != nil { continue }
            if let indexToRemove = actual.indexOf(string.hasPrefix) {
                actual.removeAtIndex(indexToRemove)
            }
        }
        XCTAssert(actual.isEmpty, "the following strings were unmatched: \(actual)")
    }

    func testSwiftDeclarationKind() {
        let expected: [SwiftDeclarationKind] = [
            .FunctionFree,
            .MethodInstance,
            .MethodStatic,
            .MethodClass,
            .AccessorGetter,
            .AccessorSetter,
            .AccessorWillSet,
            .AccessorDidSet,
            .AccessorAddress,
            .AccessorMutableAddress,
            .Constructor,
            .Destructor,
            .FunctionPrefixOperator,
            .FunctionPostfixOperator,
            .FunctionInfixOperator,
            .Subscript,
            .VarGlobal,
            .VarInstance,
            .VarStatic,
            .VarClass,
            .VarLocal,
            .VarParam,
            .Module,
            .Class,
            .Struct,
            .Enum,
            .EnumCase,
            .EnumElement,
            .Protocol,
            .Extension,
            .ExtensionStruct,
            .ExtensionClass,
            .ExtensionEnum,
            .ExtensionProtocol,
            .TypeAlias,
            .GenericTypeParam
        ]
        // SourceKit occasionally builds these through interpolation, so check prefixes only.
        var actual = sourcekitStringsStartingWith("source.lang.swift.decl.")
        for string in expected.lazy.map({ String($0.rawValue) }) {
            if actual.remove(string) != nil { continue }
            if let indexToRemove = actual.indexOf(string.hasPrefix) {
                actual.removeAtIndex(indexToRemove)
            }
        }
        XCTAssert(actual.isEmpty, "the following strings were unmatched: \(actual)")
    }

}
