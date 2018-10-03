import SwiftSyntax

extension Syntax {
    /// Used to compile the full list of parents
    /// currently being linked to current type
    func nestedTree() -> [Syntax] {
        guard let parent = parent else { return [self] }
        return [self] + parent.nestedTree()
    }
}

extension Syntax {
    /// Look to see if the syntax tree of a given syntax item
    /// contains a class
    /// if it DOES contain the passed class, it can be
    /// assumed that the declaration is at some level nested
    /// within the class
    fileprivate func parentTreeContains(_ cds: ClassDeclSyntax) -> Bool {
        guard let parent = parent else { return false }
        if let parent = parent as? ClassDeclSyntax, parent == cds { return true }
        else { return parent.parentTreeContains(cds) }
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
