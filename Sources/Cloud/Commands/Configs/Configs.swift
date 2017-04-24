import Foundation
import Core

public final class CloudConfigs: Command {
    public let id = "configs"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Interact with your cloud configurations"
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let arguments = arguments.dropFirst().array
        let token = try Token.global(with: console)

        let repo = try getRepo(
            arguments,
            console: console,
            with: token
        )

        let env: String
        if let name = arguments.option("env") {
            env = name
        } else {
            let e = try selectEnvironment(
                args: arguments,
                forRepo: repo,
                queryTitle: "Which Environment?",
                using: console,
                with: token
            )

            env = e.name
        }

        let values = arguments.values
        let input = values.first ?? ""

        let options = [
            (id: "", runner: getConfigs),
            (id: "add", runner: addConfigs),
            (id: "replace", runner: replaceConfigs),
            (id: "delete", runner: deleteConfigs),
        ]


        let selection = options.lazy.filter { id, _ in
            return id.lowercased().hasPrefix(input.lowercased())
        }.first

        let runner = selection?.runner ?? getConfigs
        try runner(values, repo, env, token)
    }

    func getConfigs(args: [String], forRepo repo: String, envName env: String, with token: Token) throws {
        let configs = try applicationApi
            .hosting
            .environments
            .configs
            .get(forRepo: repo, envName: env, with: token)

        console.success("App: ", newLine: false)
        console.print("\(repo).vapor.cloud")
        console.success("Env: ", newLine: false)
        console.print(env)
        console.print()

        configs.forEach { config in
            console.info(config.key + ": ", newLine: false)
            console.print(config.value)
        }
    }

    func addConfigs(args: [String], forRepo repo: String, envName env: String, with token: Token) throws {
        // drop 'add'
        let configs = args.values.dropFirst()
        guard !configs.isEmpty else {
            throw "No configs found to add"
        }

        var keyVal = [String: String]()
        try configs.forEach { config in
            let comps = config.makeBytes().split(
                separator: .equals,
                maxSplits: 1,
                omittingEmptySubsequences: true
            )
            guard comps.count == 2 else {
                throw "Invalid config argument \(config)"
            }
            let key = comps[0].makeString()
            let val = comps[1].makeString()
            keyVal[key] = val
        }

        _ = try applicationApi.hosting.environments.configs.add(
            keyVal,
            forRepo: repo,
            envName: env,
            with: token
        )
    }

    func replaceConfigs(args: [String], forRepo repo: String, envName env: String, with token: Token) throws {
        // drop 'replace'
        let configs = args.values.dropFirst()
        guard !configs.isEmpty else {
            throw "No configs found to add"
        }
        guard
            console.confirm("This will overwrite any existing configurations, are you sure?")
            else { return }

        var keyVal = [String: String]()
        try configs.forEach { config in
            let comps = config.makeBytes().split(
                separator: .equals,
                maxSplits: 1,
                omittingEmptySubsequences: true
            )
            guard comps.count == 2 else {
                throw "Invalid config argument \(config)"
            }
            let key = comps[0].makeString()
            let val = comps[1].makeString()
            keyVal[key] = val
        }

        _ = try applicationApi.hosting.environments.configs.replace(
            keyVal,
            forRepo: repo,
            envName: env,
            with: token
        )
    }

    func deleteConfigs(args: [String], forRepo repo: String, envName env: String, with token: Token) throws {
        // drop 'delete'
        let configs = args.values.dropFirst().array

        if configs.isEmpty {
            console.warning("Are you sure you want to delete all configurations?")
        } else {
            console.warning("Are you sure you want to delete these configurations?")
        }
        guard
            console.confirm("There is no undo.", style: .warning)
            else { return }

        _ = try applicationApi.hosting.environments.configs.delete(
            keys: configs,
            forRepo: repo,
            envName: env,
            with: token
        )
    }
}
