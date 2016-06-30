import Foundation


// MARK: ContentProvider, Path


protocol ContentProvider {
    var contents: String? { get }
}


public typealias Path = String


extension Path: ContentProvider {
    public var contents: String? {
        return try? String(contentsOfFile: self)
    }
}


// MARK: ArgumentsProvider


protocol ArgumentsProvider {
    static var arguments: [String] { get }
}


extension Process: ArgumentsProvider {}


// MARK: Utility functions


func extractPackageName(from packageFile: ContentProvider) -> String? {
    return packageFile
        .contents?
        .components(separatedBy: "\n")
        .lazy
        .map { $0.trim() }
        .filter { $0.hasPrefix("name") }
        .first?
        .components(separatedBy: "\"")
        .lazy
        .filter { !$0.hasPrefix("name") }
        .first
}



let asciiArt: [String] = [
     "               **",
     "             **~~**",
     "           **~~~~~~**",
     "         **~~~~~~~~~~**",
     "       **~~~~~~~~~~~~~~**",
     "     **~~~~~~~~~~~~~~~~~~**",
     "   **~~~~~~~~~~~~~~~~~~~~~~**",
     "  **~~~~~~~~~~~~~~~~~~~~~~~~**",
     " **~~~~~~~~~~~~~~~~~~~~~~~~~~**",
     "**~~~~~~~~~~~~~~~~~~~~~~~~~~~~**",
     "**~~~~~~~~~~~~~~~~~~~~~~~~~~~~**",
     "**~~~~~~~~~~~~~~~~~~~~~++++~~~**",
     " **~~~~~~~~~~~~~~~~~~~++++~~~**",
     "  ***~~~~~~~~~~~~~~~++++~~~***",
     "    ****~~~~~~~~~~++++~~****",
     "       *****~~~~~~~~~*****",
     "          *************",
     " ",
     " _       __    ___   ___   ___",
     "\\ \\  /  / /\\  | |_) / / \\ | |_)",
     " \\_\\/  /_/--\\ |_|   \\_\\_/ |_| \\",
     "   a web framework for Swift",
     " "
]

