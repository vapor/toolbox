import SwiftSyntax

extension ClassDeclSyntax {
    /// The first inheritance of a given class
    /// if it exists.
    /// If an inherited class exists, it will
    /// be here. It COULD be a protocol as well
    var firstInheritance: String? {
        return inheritanceClause?
            .inheritedTypeCollection
            .first?
            .typeName
            .description
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// If this class inherits from XCTestCase
    var inheritsDirectlyFromXCTestCase: Bool {
        return firstInheritance == "XCTestCase"
    }

    /// Whether this class, or some class in its inheritance
    /// tree inherits from XCTestCase making it a valid
    /// XCTestCase
    func inheritsXCTestCase(using list: [ClassDeclSyntax]) -> Bool {
        if inheritsDirectlyFromXCTestCase { return true }
        guard let inheritance = findDeclaredInheritance(using: list) else { return false }
        return inheritance.inheritsXCTestCase(using: list)
    }

    /// Find the inherited class from a array of available classes
    func findDeclaredInheritance(using list: [ClassDeclSyntax]) -> ClassDeclSyntax? {
        guard let first = firstInheritance else { return nil }
        let tree = declarationTree()
        // .dropLast() == removeSelf
        let nestingsMinusSelf = tree.dropLast()
        let potentiallyNestedInheritance = Array(nestingsMinusSelf + [first])

        let nestedResult = list.first { cds in
            potentiallyNestedInheritance == cds.declarationTree()
        }
        if let nestedResult = nestedResult { return nestedResult }
        else {
            return list.first { cds in
                cds.flattenedName() == first
            }
        }
    }
}

extension Array where Element == ClassDeclSyntax {
    /// Convert an extensionn to a class
    /// in a given list of classes
    func classMatching(_ exten: ExtensionDeclSyntax) -> ClassDeclSyntax? {
        return first { cds in
            let name = cds.flattenedName()
            return name == exten.extendedTypeName
        }
    }
}
