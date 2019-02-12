import SwiftSyntax

/// Adds behavior to type declarations
/// Enum, Struct, Class
/// Omits other declaration types, ie:
/// protocol, extension, function, etc.
protocol TypeDeclSyntax {
    var identifier: TokenSyntax { get }
}
extension ClassDeclSyntax: TypeDeclSyntax {}
extension EnumDeclSyntax: TypeDeclSyntax {}
extension StructDeclSyntax: TypeDeclSyntax {}
extension DeclSyntax where Self: TypeDeclSyntax {
    /// Used to combine with outer names, for
    /// nested type declarations ie:
    /// class A { class B {
    /// B => A.B
    func flattenedName() -> String {
        return declarationTree().joined(separator: ".")
    }

    /// The outer declaration tree of a given declaration
    /// Used to deconstruct full name
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
