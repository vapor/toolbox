import SwiftSyntax

extension ExtensionDeclSyntax {
    var extendedTypeName: String {
        return extendedType.description.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
