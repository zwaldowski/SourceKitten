//
//  SwiftDocsTests.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-03.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Foundation
@testable import SourceKittenFramework
import XCTest

func compareJSONStringWithFixturesName(name: String, jsonString: String, file: String = __FILE__, line: UInt = __LINE__) {
    func jsonValue(jsonString: String) -> AnyObject {
        let data = jsonString.dataUsingEncoding(NSUTF8StringEncoding)!
        let result = try! NSJSONSerialization.JSONObjectWithData(data, options: [])
        return (result as? NSDictionary) ?? (result as! NSArray)
    }
    let firstValue = jsonValue(jsonString)
    let secondValue = jsonValue(File(path: fixturesDirectory + name + ".json")!.contents)
    let message = "output should match expected fixture"
    if let firstValue = firstValue as? NSDictionary, secondValue = secondValue as? NSDictionary {
        XCTAssertEqual(firstValue, secondValue, message, file: file, line: line)
    } else if let firstValue = firstValue as? NSArray, secondValue = secondValue as? NSArray {
        XCTAssertEqual(firstValue, secondValue, message, file: file, line: line)
    } else {
        XCTFail("output didn't match fixture type", file: file, line: line)
    }
}

func compareDocsWithFixturesName(name: String, file: String = __FILE__, line: UInt = __LINE__) {
    let swiftFilePath = fixturesDirectory + name + ".swift"
    let docs = SwiftDocs(file: File(path: swiftFilePath)!, arguments: ["-j4", swiftFilePath])!

    let escapedFixturesDirectory = fixturesDirectory.stringByReplacingOccurrencesOfString("/", withString: "\\/")
    let comparisonString = String(docs).stringByReplacingOccurrencesOfString(escapedFixturesDirectory, withString: "")
    compareJSONStringWithFixturesName(name, jsonString: comparisonString)
}

class SwiftDocsTests: XCTestCase {

    // protocol XCTestCaseProvider
    lazy var allTests: [(String, () throws -> Void)] = [
        // ("testSubscript", self.testSubscript), FIXME: Failing on SPM
        // ("testBicycle", self.testBicycle), FIXME: Failing on SPM
        ("testParseFullXMLDocs", self.testParseFullXMLDocs),
    ]

    func testSubscript() {
        compareDocsWithFixturesName("Subscript")
    }

    func testBicycle() {
        compareDocsWithFixturesName("Bicycle")
    }

    func testParseFullXMLDocs() {
        let xmlDocsString = "<Type file=\"file\" line=\"1\" column=\"2\"><Name>name</Name><USR>usr</USR><Declaration>declaration</Declaration><Abstract><Para>discussion</Para></Abstract><Parameters><Parameter><Name>param1</Name><Direction isExplicit=\"0\">in</Direction><Discussion><Para>param1_discussion</Para></Discussion></Parameter></Parameters><ResultDiscussion><Para>result_discussion</Para></ResultDiscussion></Type>"
        let parsed = SwiftCursorDocumentation(XMLDocs: xmlDocsString)!
        XCTAssertEqual(parsed.location.filename, "file")
        XCTAssertEqual(parsed.location.line, 1)
        XCTAssertEqual(parsed.location.column, 2)
        XCTAssertEqual(parsed.location.offset, 0)
        XCTAssertEqual(parsed.name, "name")
        XCTAssertEqual(parsed.symbol, "usr")
        XCTAssertEqual(parsed.declaration, "declaration")

        let paramDiscussion = Parameter(name: "param1", discussion: [
            .Para("param1_discussion", nil)
        ])
        XCTAssert(parsed.documentation.parameters.elementsEqual(CollectionOfOne(paramDiscussion)))

        let returnDiscussion = Text.Para("result_discussion", nil)
        XCTAssert(parsed.documentation.returnDiscussion.elementsEqual(CollectionOfOne(returnDiscussion)))
    }
}
