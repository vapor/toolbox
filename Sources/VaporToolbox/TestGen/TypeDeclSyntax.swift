import SwiftSyntax

protocol TypeDeclSyntax {
    var identifier: TokenSyntax { get }
}
extension ClassDeclSyntax: TypeDeclSyntax {}
extension EnumDeclSyntax: TypeDeclSyntax {}
extension StructDeclSyntax: TypeDeclSyntax {}
extension DeclSyntax where Self: TypeDeclSyntax {
    func flattenedName() throws -> String {
        return try declarationTree().joined(separator: ".")
    }

    func declarationTree() throws -> [String] {
        if isNestedInTypeDecl {
            guard let outer = outerTypeDecl() else { throw "unable to find expected outer type decl" }
            return try outer.declarationTree() + [identifier.text]
        }
        if isNestedInExtension {
            guard let outer = outerExtensionDecl() else { throw "unable to find outer class" }
            return [
                outer.extendedTypeName,
                identifier.text
            ]
        }
        return [identifier.text]
    }
}
