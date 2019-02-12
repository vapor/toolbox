import SwiftSyntax

extension Syntax {
    /// Used to compile the full list of parents
    /// currently being linked to current type
    func nestedTree() -> [Syntax] {
        guard let parent = parent else { return [self] }
        return [self] + parent.nestedTree()
    }
}

extension Array where Element == Syntax {
    /// If a given nested tree contains either a
    /// class, or an extension.
    /// Test functions can only be declared within
    /// a class, or an extension of a class
    var containsClassOrExtension: Bool {
        return contains { $0 is ExtensionDeclSyntax || $0 is ClassDeclSyntax}
    }
}
