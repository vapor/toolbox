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

    func inheritsXCTestCase(using list: [ClassDeclSyntax]) throws -> Bool {
        if inheritsDirectlyFromXCTestCase { return true }
        guard let inheritance = try findDeclaredInheritance(using: list) else { return false }
        return try inheritance.inheritsXCTestCase(using: list)
    }

    func findDeclaredInheritance(using list: [ClassDeclSyntax]) throws -> ClassDeclSyntax? {
        guard let first = firstInheritance else { return nil }
        let tree = try declarationTree()
        // .dropLast() == removeSelf
        let nestingsMinusSelf = tree.dropLast()
        let potentiallyNestedInheritance = Array(nestingsMinusSelf + [first])

        let nestedResult = try list.first { cds in
            try potentiallyNestedInheritance == cds.declarationTree()
        }
        if let nestedResult = nestedResult { return nestedResult }
        else {
            return try list.first { cds in
                try cds.flattenedName() == first
            }
        }
    }
}

extension Array where Element == ClassDeclSyntax {
    func classMatching(_ exten: ExtensionDeclSyntax) throws -> ClassDeclSyntax? {
        return try first { cds in
            let name = try cds.flattenedName()
            return name == exten.extendedTypeName
        }
    }
}
