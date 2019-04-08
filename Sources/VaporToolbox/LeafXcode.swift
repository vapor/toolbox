import Vapor
import Globals
import LeafKit

public struct LeafGroup: CommandGroup {
    public let commands: Commands = [
        "render": LeafRenderFolder()
    ]

    public let options: [CommandOption] = []

    /// See `CommandGroup`.
    public var help: [String] = [
        "commands for interacting with leaf"
    ]

    public init() {}

    /// See `CommandGroup`.
    public func run(using ctx: CommandContext) throws -> EventLoopFuture<Void> {
        return ctx.done
    }
}

extension Seed {
    struct Question: Content {
        let `var`: String
        let display: String
        let choices: [String]?
        let `default`: String?
        let conditions: [Condition]?
    }
}

extension Seed {
    struct ConditionalInclude: Codable {
        let condition: Seed.Condition
        let includes: [String]
    }
    
    enum Exclusion: Codable {
        // has trailing `/`, ie: `images/`
        case folder(String)
        // has leading `*`, ie: `*.jpg`
        case fileType(String)
        // all others will be interpreted as a file
        case file(String)

        private var str: String {
            switch self {
            case .folder(let s): return s
            case .fileType(let s): return "*" + s
            case .file(let s): return s
            }
        }

        func encode(to encoder: Encoder) throws {
            var single = encoder.singleValueContainer()
            try single.encode(str)
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            if value.hasPrefix("*") {
                let stripped = value.dropFirst()
                let type = String(stripped)
                self = .fileType(type)
            } else if value.hasSuffix("/") {
                self = .folder(value)
            } else {
                self = .file(value)
            }
        }
    }
    
    struct Condition: Codable {
        let `var`: String
        let equals: String?
        let `in`: [String]?
    }
}

extension Array where Element == Seed.Exclusion {
    func shouldExclude(path: String) -> Bool {
        for exclusion in self {
            if exclusion.matches(path: path) { return true }
        }
        return false
    }
}

extension Seed.Exclusion {
    func matches(path: String) -> Bool {
        switch self {
        case .folder(let f):
            return path.finished(with: "/").contains(f)
        case .fileType(let t):
            return path.hasSuffix(t)
        case .file(let f):
            return path.hasSuffix(f)
        }
    }
}

struct Seed: Content {
    let name: String
    let excludes: [Exclusion]
    let questions: [Question]
    let conditionalIncludes: [ConditionalInclude]?
}

extension Seed {
    struct Answer {
        let val: String
        let question: Question
    }
}

extension Console {
    func answer(_ questions: [Seed.Question]) throws -> [Seed.Answer] {
        var answered: [Seed.Answer] = []
        for question in questions {
            if let res = answer(question, answered: answered) {
                answered.append(res)
            }
        }
        return answered
    }

    private func answer(_ question: Seed.Question, answered: [Seed.Answer]) -> Seed.Answer? {
        if let condition = question.conditions {
            guard answered.satisfy(condition) else { return nil }
        }

        let val = fulfill(question)
        let readable = question.var + ": "
        output(readable.consoleText(), newLine: false)
        output(val.consoleText())
        return Seed.Answer(val: val, question: question)
    }

    private func fulfill(_ question: Seed.Question) -> String {
        if let choices = question.choices {
            return choose(question.display.consoleText(), from: choices)
        }

        // only run on non-choose, choose above will clear on its own
        pushEphemeral()
        defer { popEphemeral() }
        if let def = question.default {
            let question = question.display + " (\(def) is default)"
            let answer =  ask(question.consoleText())
            if answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return def }
            else { return def }
        } else {
            return ask(question.display.consoleText())
        }
    }

}

extension Array where Element == Seed.Answer {
    func satisfy(_ conditions: [Seed.Condition]) -> Bool {
        for condition in conditions {
            guard satisfy(condition) else { return false }
        }
        return true
    }
    
    func satisfy(_ condition: Seed.Condition) -> Bool {
        let matching = first { $0.question.var == condition.var }
        guard let answer = matching else { return false }
        if let expectation = condition.equals { return expectation == answer.val }
        if let `in` = condition.in { return `in`.contains(answer.val) }
        return false
    }
    
    func package() -> [String: String] {
        var pack = [String: String]()
        forEach { answer in
            pack[answer.question.var] = answer.val
        }
        return pack
    }
}

extension CommandOption {
    static let path: CommandOption = .value(
        name: "path",
        short: "p",
        default: "./",
        help: ["the path to the folder that should be rendered. defaults to current path"]
    )
}

struct LeafRenderFolder: Command {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = [
        .path
    ]

    /// See `Command`.
    var help: [String] = ["leaf package stuff"]

    /// See `Command`.
    func run(using ctx: CommandContext) throws -> EventLoopFuture<Void> {
        let raw = ctx.options.value(.path) ?? "./"

        // expand `~` for example
        let path = try Shell.bash("echo \(raw)")
        guard FileManager.default.isDirectory(path: path) else {
            throw "expected a directory, got \(path)"
        }

        // MARK: Compile Package
        let seedPath = path.finished(with: "/") + "leaf.seed"
        let contents = try Shell.readFile(path: seedPath)
        let data = Data(bytes: contents.utf8)
        let decoder = JSONDecoder()
        let seed = try decoder.decode(Seed.self, from: data)
        let answers = try ctx.console.answer(seed.questions)
        let package = answers.package()

        // MARK: Collect Paths
        let all = try FileManager.default.allFiles(at: path)
        
        let config = LeafConfig(rootDirectory: path)
        let threadPool = NIOThreadPool(numberOfThreads: 1)
        threadPool.start()
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let renderer = LeafRenderer(config: config, threadPool: threadPool, eventLoop: ctx.eventLoop)
        let paths = all.filter { !seed.excludes.shouldExclude(path: $0) }

        // MARK: Render Files
        var renders: [EventLoopFuture<(ByteBuffer, String)>] = []
        for path in paths {
//            let contents = try Shell.readFile(path: path)
//            let data = Data(bytes: contents.utf8)
            var data: [String: LeafData] = [:]
            package.forEach { key, val in
                data[key] = .string(val)
            }
            let rendered = renderer.render(path: path, context: data).and(value: path)
//            let rendered = renderer.render(template: data, package).and(result: path)
            renders.append(rendered)
        }

        // MARK: Write Files
                todo()
//        let flat = renders.flatten(on: ctx.container)
//        return flat.map { views in
//            for (view, path) in views {
//                let url = URL(fileURLWithPath: path)
//                guard let str = String(bytes: view.data, encoding: .utf8) else {
//                    fatalError("unable to create string") }
//                if str.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
//                    try Shell.delete(path)
//                } else {
//                    try view.data.write(to: url)
//                }
//            }
//
//            try Shell.delete(seedPath)
//            // TODO: Delete Empty Folders?
//        } .map {
//            try seed.conditionalIncludes?.forEach { include in
//                if answers.satisfy(include.condition) { return }
//                else {
//                    try include.includes.map { path.finished(with: "/") + $0 } .forEach(Shell.delete)
//                }
//            }
//        }
    }
}

extension FileManager {
    func isDirectory(path: String) -> Bool {
        var isDirectory: ObjCBool = false
        fileExists(atPath: path, isDirectory: &isDirectory)
        return isDirectory.boolValue
    }

    func allFiles(at path: String) throws -> [String] {
        let path = path.finished(with: "/")
        guard isDirectory(path: path) else { throw path + " is not a directory." }

        let excludes = [
            ".git",
            ".gitignore",
            ".DS_Store"
        ]
        let paths = try contentsOfDirectory(atPath: path)
            .filter { !excludes.contains($0) }
            .map { path + $0 }

        return try paths.reduce([]) { all, next in
            if isDirectory(path: next) { return try all + allFiles(at: next) }
            else { return all + [next] }
        }
    }
}
