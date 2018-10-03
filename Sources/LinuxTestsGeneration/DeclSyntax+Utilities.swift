import SwiftSyntax

extension DeclSyntax {
    var isNestedInExtension: Bool {
        return nestedTree().dropFirst().contains { $0 is ExtensionDeclSyntax }
    }

    var isNestedInClass: Bool {
        return nestedTree().dropFirst().contains { $0 is ClassDeclSyntax }
    }

    var isNestedInStruct: Bool {
        return nestedTree().dropFirst().contains { $0 is StructDeclSyntax }
    }

    var isNestedInEnum: Bool {
        return nestedTree().dropFirst().contains { $0 is EnumDeclSyntax }
    }

    var isNestedInTypeDecl: Bool {
        return nestedTree().dropFirst().contains { $0 is (DeclSyntax & TypeDeclSyntax) }
    }
}

extension DeclSyntax {
    func outerClassDecl() -> ClassDeclSyntax? {
        return nestedTree().dropFirst().compactMap { $0 as? ClassDeclSyntax } .first
    }

    func outerStructDecl() -> StructDeclSyntax? {
        return nestedTree().dropFirst().compactMap { $0 as? StructDeclSyntax } .first
    }

    func outerExtensionDecl() -> ExtensionDeclSyntax? {
        return nestedTree().dropFirst().compactMap { $0 as? ExtensionDeclSyntax } .first
    }

    func outerEnumDecl() -> EnumDeclSyntax? {
        return nestedTree().dropFirst().compactMap { $0 as? EnumDeclSyntax } .first
    }

    func outerTypeDecl() -> (DeclSyntax & TypeDeclSyntax)? {
        return nestedTree().dropFirst().compactMap { $0 as? (DeclSyntax & TypeDeclSyntax) } .first
    }
}
