import SwiftSyntax

extension Syntax {
    func nestedTree() -> [Syntax] {
        guard let parent = parent else { return [self] }
        return [self] + parent.nestedTree()
    }
}

extension Syntax {
    fileprivate func parentTreeContains(_ cds: ClassDeclSyntax) -> Bool {
        guard let parent = parent else { return false }
        if let parent = parent as? ClassDeclSyntax, parent == cds { return true }
        else { return parent.parentTreeContains(cds) }
    }
}

extension Array where Element == Syntax {
    var containsClassOrExtension: Bool {
        return contains { $0 is ExtensionDeclSyntax || $0 is ClassDeclSyntax}
    }
}
