import SwiftSyntax

extension Syntax {
    func nestedTree() -> [Syntax] {
        guard let parent = parent else { return [self] }
        return [self] + parent.nestedTree()
    }
}
