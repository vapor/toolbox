import SwiftSyntax

extension FunctionDeclSyntax {
    /// During gathering, we will do a soft filter
    /// for functions that look like they could be
    /// test functions. After that, we will process
    /// whether their declarations are within
    /// a test case
    var looksLikeTestFunction: Bool {
        guard
            // all tests MUST begin w/ 'test' as prefix
            identifier.text.hasPrefix("test"),
            // all tests MUST take NO arguments
            signature.input.parameterList.count == 0,
            // all tests MUST have no output
            signature.output == nil,
            // all tests MUST be declared w/in a class,
            // or an extension of a class
            nestedTree().containsClassOrExtension
            else { return false }
        return true
    }
}

extension FunctionDeclSyntax {
    /// Find the test case in which this function is declared
    func testCase(from cases: [ClassDeclSyntax]) -> ClassDeclSyntax? {
        if let cd = outerClassDecl(), cases.contains(cd) {
            return cd
        } else if let ext = outerExtensionDecl(), let matched = cases.classMatching(ext) {
            return matched
        } else {
            return nil
        }
    }
}
