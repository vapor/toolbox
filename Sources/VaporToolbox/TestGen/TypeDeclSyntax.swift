import SwiftSyntax

protocol TypeDeclSyntax {
    var identifier: TokenSyntax { get }
}
extension ClassDeclSyntax: TypeDeclSyntax {}
extension EnumDeclSyntax: TypeDeclSyntax {}
extension StructDeclSyntax: TypeDeclSyntax {}
extension DeclSyntax where Self: TypeDeclSyntax {
    func flattenedName() -> String {
        return declarationTree().joined(separator: ".")
    }

    func declarationTree() -> [String] {
        if let outerType = outerTypeDecl() {
            return outerType.declarationTree() + [identifier.text]
        }

        if let ext = outerExtensionDecl() {
            return [
                ext.extendedTypeName,
                identifier.text
            ]
        }

        return [identifier.text]
    }
}
