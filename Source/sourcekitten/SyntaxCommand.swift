//
//  Syntax.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-07.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

import Commandant
import Curry
import Foundation
import Result
import SourceKittenFramework

struct SyntaxCommand: CommandType {
    let verb = "syntax"
    let function = "Print Swift syntax information as JSON"

    func run(options: SyntaxOptions) -> Result<(), SourceKittenError> {
        if !options.file.isEmpty {
            if let file = File(path: options.file) {
                do {
                    print(try SyntaxMap(file: file))
                    return .Success()
                } catch let error as Response.Error {
                    return .Failure(.SourceKitError(error))
                } catch {
                    return .Failure(error as! SourceKittenError)
                }
            }
            return .Failure(.ReadFailed(path: options.file))
        }
        do {
            try print(SyntaxMap(file: File(contents: options.text)))
            return .Success()
        } catch let error as Response.Error {
            return .Failure(.SourceKitError(error))
        } catch {
            return .Failure(error as! SourceKittenError)
        }
    }
}

struct SyntaxOptions: OptionsType {
    let file: String
    let text: String

    static func evaluate(m: CommandMode) -> Result<SyntaxOptions, CommandantError<SourceKittenError>> {
        return curry(self.init)
            <*> m <| Option(key: "file", defaultValue: "", usage: "relative or absolute path of Swift file to parse")
            <*> m <| Option(key: "text", defaultValue: "", usage: "Swift code text to parse")
    }
}
