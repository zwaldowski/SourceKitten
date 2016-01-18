//
//  SwiftDeclarationKind.swift
//  SourceKitten
//
//  Created by JP Simard on 2015-01-05.
//  Copyright (c) 2015 SourceKitten. All rights reserved.
//

/// Swift declaration kinds.
/// https://github.com/apple/swift/blob/master/tools/SourceKit/lib/SwiftLang/SwiftLangSupport.cpp
public enum SwiftDeclarationKind: UID {
    /// `func` in the global context.
    case FunctionFree            = "source.lang.swift.decl.function.free"
    /// `func` in the type context.
    case MethodInstance          = "source.lang.swift.decl.function.method.instance"
    /// `static func`.
    case MethodStatic            = "source.lang.swift.decl.function.method.static"
    /// `class func`.
    case MethodClass             = "source.lang.swift.decl.function.method.class"
    /// `get` in a computed property.
    case AccessorGetter          = "source.lang.swift.decl.function.accessor.getter"
    /// `set` in a computed property.
    case AccessorSetter          = "source.lang.swift.decl.function.accessor.setter"
    /// `willSet` in a computed property.
    case AccessorWillSet         = "source.lang.swift.decl.function.accessor.willset"
    /// `didSet` in a computed property.
    case AccessorDidSet          = "source.lang.swift.decl.function.accessor.didset"
    /// `address` in a computed property.
    case AccessorAddress         = "source.lang.swift.decl.function.accessor.address"
    /// `mutableAddress` in a computed property.
    case AccessorMutableAddress  = "source.lang.swift.decl.function.accessor.mutableaddress"
    /// `init`.
    case Constructor             = "source.lang.swift.decl.function.constructor"
    /// `deinit`.
    case Destructor              = "source.lang.swift.decl.function.destructor"
    /// `prefix operator`.
    case FunctionPrefixOperator  = "source.lang.swift.decl.function.operator.prefix"
    /// `postfix operator`.
    case FunctionPostfixOperator = "source.lang.swift.decl.function.operator.postfix"
    /// `infix operator`.
    case FunctionInfixOperator   = "source.lang.swift.decl.function.operator.infix"
    /// `subscript`.
    case Subscript               = "source.lang.swift.decl.function.subscript"
    /// `var` in the global context.
    case VarGlobal               = "source.lang.swift.decl.var.global"
    /// `var` in the type context.
    case VarInstance             = "source.lang.swift.decl.var.instance"
    /// `static var`.
    case VarStatic               = "source.lang.swift.decl.var.static"
    /// `class var`.
    case VarClass                = "source.lang.swift.decl.var.class"
    /// `var` in the function context.
    case VarLocal                = "source.lang.swift.decl.var.local"
    /// `var` as a parameter to a function.
    case VarParam                = "source.lang.swift.decl.var.parameter"
    /// A module token in an `import` statement.
    case Module                  = "source.lang.swift.decl.module"
    /// `class`.
    case Class                   = "source.lang.swift.decl.class"
    /// `struct`.
    case Struct                  = "source.lang.swift.decl.struct"
    /// `enum`.
    case Enum                    = "source.lang.swift.decl.enum"
    /// `case`.
    case EnumCase                = "source.lang.swift.decl.enumcase"
    /// Accessing `case`s through type dot syntax on an `enum` type.
    case EnumElement             = "source.lang.swift.decl.enumelement"
    /// `protocol`.
    case Protocol                = "source.lang.swift.decl.protocol"
    /// `extension`.
    case Extension               = "source.lang.swift.decl.extension"
    /// `extension` on a `struct` type.
    case ExtensionStruct         = "source.lang.swift.decl.extension.struct"
    /// `extension` on a `class` type.
    case ExtensionClass          = "source.lang.swift.decl.extension.class"
    /// `extension` on an `enum` type.
    case ExtensionEnum           = "source.lang.swift.decl.extension.enum"
    /// `extension` on a `protocol` type.
    case ExtensionProtocol       = "source.lang.swift.decl.extension.protocol"
    /// `typealias`.
    case TypeAlias               = "source.lang.swift.decl.typealias"
    /// A parameter token in a generic type context.
    case GenericTypeParam        = "source.lang.swift.decl.generic_type_param"
}

/// Swift declaration kinds.
/// Found in `strings SourceKitService | grep source.lang.swift.decl.`.
@available(*, deprecated)
public enum SwiftDeclarationKindOld: String {
    /// `class`.
    case Class = "source.lang.swift.decl.class"
    /// `enum`.
    case Enum = "source.lang.swift.decl.enum"
    /// `enumcase`.
    case Enumcase = "source.lang.swift.decl.enumcase"
    /// `enumelement`.
    case Enumelement = "source.lang.swift.decl.enumelement"
    /// `extension`.
    case Extension = "source.lang.swift.decl.extension"
    /// `extension.class`.
    case ExtensionClass = "source.lang.swift.decl.extension.class"
    /// `extension.enum`.
    case ExtensionEnum = "source.lang.swift.decl.extension.enum"
    /// `extension.protocol`.
    case ExtensionProtocol = "source.lang.swift.decl.extension.protocol"
    /// `extension.struct`.
    case ExtensionStruct = "source.lang.swift.decl.extension.struct"
    /// `function.accessor.address`.
    case FunctionAccessorAddress = "source.lang.swift.decl.function.accessor.address"
    /// `function.accessor.didset`.
    case FunctionAccessorDidset = "source.lang.swift.decl.function.accessor.didset"
    /// `function.accessor.getter`.
    case FunctionAccessorGetter = "source.lang.swift.decl.function.accessor.getter"
    /// `function.accessor.mutableaddress`.
    case FunctionAccessorMutableaddress = "source.lang.swift.decl.function.accessor.mutableaddress"
    /// `function.accessor.setter`.
    case FunctionAccessorSetter = "source.lang.swift.decl.function.accessor.setter"
    /// `function.accessor.willset`.
    case FunctionAccessorWillset = "source.lang.swift.decl.function.accessor.willset"
    /// `function.constructor`.
    case FunctionConstructor = "source.lang.swift.decl.function.constructor"
    /// `function.destructor`.
    case FunctionDestructor = "source.lang.swift.decl.function.destructor"
    /// `function.free`.
    case FunctionFree = "source.lang.swift.decl.function.free"
    /// `function.method.class`.
    case FunctionMethodClass = "source.lang.swift.decl.function.method.class"
    /// `function.method.instance`.
    case FunctionMethodInstance = "source.lang.swift.decl.function.method.instance"
    /// `function.method.static`.
    case FunctionMethodStatic = "source.lang.swift.decl.function.method.static"
    /// `function.operator`.
    case FunctionOperator = "source.lang.swift.decl.function.operator"
    /// `function.subscript`.
    case FunctionSubscript = "source.lang.swift.decl.function.subscript"
    /// `generic_type_param`.
    case GenericTypeParam = "source.lang.swift.decl.generic_type_param"
    /// `module`
    case Module = "source.lang.swift.decl.module"
    /// `protocol`.
    case Protocol = "source.lang.swift.decl.protocol"
    /// `struct`.
    case Struct = "source.lang.swift.decl.struct"
    /// `typealias`.
    case Typealias = "source.lang.swift.decl.typealias"
    /// `var.class`.
    case VarClass = "source.lang.swift.decl.var.class"
    /// `var.global`.
    case VarGlobal = "source.lang.swift.decl.var.global"
    /// `var.instance`.
    case VarInstance = "source.lang.swift.decl.var.instance"
    /// `var.local`.
    case VarLocal = "source.lang.swift.decl.var.local"
    /// `var.parameter`.
    case VarParameter = "source.lang.swift.decl.var.parameter"
    /// `var.static`.
    case VarStatic = "source.lang.swift.decl.var.static"
}
