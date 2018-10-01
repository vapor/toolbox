import SwiftSyntax

extension ClassDeclSyntax {
    var firstInheritance: String? {
        return inheritanceClause?
            .inheritedTypeCollection
            .first?
            .typeName
            .description
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var inheritsDirectlyFromXCTestCase: Bool {
        return firstInheritance == "XCTestCase"
    }

    func inheritsXCTestCase(using list: [ClassDeclSyntax]) -> Bool {
        if inheritsDirectlyFromXCTestCase { return true }
        guard let inheritance = findDeclaredInheritance(using: list) else { return false }
        return inheritance.inheritsXCTestCase(using: list)
    }

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
    func classMatching(_ exten: ExtensionDeclSyntax) -> ClassDeclSyntax? {
        return first { cds in
            let name = cds.flattenedName()
            return name == exten.extendedTypeName
        }
    }
}
