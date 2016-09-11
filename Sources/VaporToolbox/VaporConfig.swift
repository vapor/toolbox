import Node
import JSON
import Core
import Foundation

protocol ConfigKey {
    var name: String { get }
    func merge(nodes: [Node]) throws -> Node
}

extension Node {
    /**
     Load the file at a path as raw bytes, or as parsed JSON representation
     */
    static func loadContents(path: String) throws -> Node {
        let data = try DataFile().load(path: path)
        guard path.hasSuffix(".json") else { return .bytes(data) }
        return try JSON(bytes: data).converted()
    }
}

/**
 Not publicizing these because there's some nuance specific to config
 */
extension FileManager {
    func vaporConfigFiles(rootDirectory: String = "./") throws -> [Node] {
        let rootDirectory = rootDirectory.finished(with: "/")

        let rootConfig = loadVaporConfig(directory: rootDirectory)

        let packagesDirectory = rootDirectory + "Packages/"
        let packagesConfigs = try subDirectories(root: packagesDirectory)
            .map { packagesDirectory + $0 }
            .flatMap(loadVaporConfig)

        return rootConfig.flatMap { [$0] + packagesConfigs } ?? packagesConfigs
    }

    private func loadVaporConfig(directory: String) -> Node? {
        let directory = directory.finished(with: "/")
        return try? Node.loadContents(path: directory + "vapor.json")
    }

    private func subDirectories(root: String) throws -> [String] {
        guard isDirectory(path: root) else { return [] }
        return try contents(directory: root).filter(isDirectory)
    }

    private func vaporConfigFilesRecursively(directory: String) throws -> [Node] {
        let directory = directory.finished(with: "/")

        let contents = try contentsOfDirectory(atPath: directory)

        var configs = [Node]()
        if let config = try? Node.loadContents(path: directory + "vapor.json") {
            configs.append(config)
        }
        return try configs
            + contents.map { directory + $0 }
            .filter(isDirectory)
            .flatMap(vaporConfigFilesRecursively)
    }

    fileprivate func isDirectory(path: String) -> Bool {
        var isDirectory: ObjCBool = false
        _ = fileExists(atPath: path, isDirectory: &isDirectory)
        #if os(Linux)
            return isDirectory
        #else
            return isDirectory.boolValue
        #endif
    }

    fileprivate func files(path: String) throws -> [String] {
        let path = path.finished(with: "/")
        guard isDirectory(path: path) else { return [] }
        let subPaths = try subpathsOfDirectory(atPath: path)
        return subPaths.filter { !$0.contains("/") && !isDirectory(path: path + $0) && $0 != ".DS_Store" }
    }

    private func contents(directory: String, recursive: Bool = false) throws -> [String] {
        guard recursive else { return try contentsOfDirectory(atPath: directory) }
        guard let cursor = enumerator(atPath: directory) else { return [] }
        var contents: [String] = []
        while let next = cursor.nextObject() {
            contents.append("\(next)")
        }
        return contents
    }
}
