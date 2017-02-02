import Console

internal let defaultTemplatesDirectory = ".build/Templates/"
internal let defaultTemplatesURLString = "https://gist.github.com/1b9b58c0ca4dbe3538b2707df5959d80.git"

public protocol Generator {
    var console: ConsoleProtocol { get }
    init(console: ConsoleProtocol)
    func generate(arguments: [String]) throws
}
