import Basic
import PackageGraph
import PackageLoading
import SourceControl
import Vapor
import Workspace
import Xcodeproj

/// Generates an Xcode project for SPM packages.
struct XcodeCommand: Command {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = []

    /// See `Command`.
    var help: [String] = ["Generates Xcode projects for SPM packages."]

    /// See `Command`.
    func run(using ctx: CommandContext) throws -> Future<Void> {
        ctx.console.output("Loading package graph...")
        let rootPath = currentWorkingDirectory
        let manifestLoader = ManifestLoader(
            resources: BasicManifestResourceProvider(
                swiftCompiler: "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc",
                libDir: "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm"
            )
        )
        let provider = GitRepositoryProvider(processSet: ProcessSet())
        let workspace = Workspace(
            dataPath: rootPath.appending(component: ".build"),
            editablesPath: rootPath.appending(component: "Packages"),
            pinsFile: rootPath.appending(component: "Package.resolved"),
            manifestLoader: manifestLoader,
            toolsVersionLoader: ToolsVersionLoader(),
            delegate: ConsoleWorkspaceDelegate(console: ctx.console),
            repositoryProvider: provider,
            isResolverPrefetchingEnabled: true,
            skipUpdate: false
        )
        let rootInput = PackageGraphRootInput(packages: [rootPath])
        let engine = DiagnosticsEngine()
        let graph = workspace.loadPackageGraph(root: rootInput, diagnostics: engine)
        let options = XcodeprojOptions()

        guard !graph.rootPackages.isEmpty else {
            engine.diagnostics.forEach { ctx.console.diagnostic($0) }
            throw VaporError(identifier: "noRootPackage", reason: "No root package found.")
        }
        let name = graph.rootPackages[0].name
        let xcodeprojPath = rootPath.appending(component: name + ".xcodeproj")
        ctx.console.output("Generating Xcode project for " + name.consoleText(.info) + "...")
        try generate(projectName: name, xcodeprojPath: xcodeprojPath, graph: graph, options: options)
        let prettyPath = xcodeprojPath.prettyPath(cwd: rootPath)

        engine.diagnostics.forEach { ctx.console.diagnostic($0) }
        if ctx.console.confirm("Open " + prettyPath.consoleText(color: .magenta) + "?") {
            _ = try Process.execute("open", xcodeprojPath.asString)
        }
        return .done(on: ctx.container)
    }
}

struct BasicManifestResourceProvider: ManifestResourceProvider {
    var swiftCompiler: AbsolutePath
    var libDir: AbsolutePath
}

extension Console {
    func diagnostic(_ diagnostic: Diagnostic) {
        let prefix: ConsoleText
        switch diagnostic.behavior {
        case .error: prefix = "error: ".consoleText(.error)
        case .ignored: return
        case .note: prefix = "info: ".consoleText(.info)
        case .warning: prefix = "warning: ".consoleText(.warning)
        }
        output(prefix + diagnostic.localizedDescription.consoleText())
    }
}

final class ConsoleWorkspaceDelegate: WorkspaceDelegate {
    enum FetchStatus {
        case begin
        case fetched(Diagnostic?)
        case cloning
    }

    let console: Console
    var fetches: [(String, FetchStatus)]

    init(console: Console) {
        self.console = console
        self.fetches = []
    }

    func packageGraphWillLoad(currentGraph: PackageGraph, dependencies: AnySequence<ManagedDependency>, missingURLs: Set<String>) {
        console.print("\(#function): \(currentGraph)")
    }

    func fetchingWillBegin(repository: String) {
        addFetch(repo: repository, status: .begin)
    }

    func fetchingDidFinish(repository: String, diagnostic: Diagnostic?) {
        addFetch(repo: repository, status: .fetched(diagnostic))
    }

    func cloning(repository: String) {
        addFetch(repo: repository, status: .cloning)
    }

    func addFetch(repo: String, status: FetchStatus) {
        console.clear(lines: fetches.count + 1)
        if let idx = fetches.index(where: { $0.0 == repo }) {
            fetches[idx] = (repo, status)
        } else {
            fetches.append((repo, status))
        }
        drawFetches()
        console.output("Loading package graph...")
    }

    func drawFetches() {
        for (repo, status) in fetches {
            switch status {
            case .begin:
                console.output(repo.githubReadable.consoleText() + " [Discovered]".consoleText(.warning))
            case .fetched(let diagnostic):
                if let d = diagnostic {
                    console.output(repo.githubReadable.consoleText() + " [\(d.localizedDescription)]".consoleText(.error))
                } else {
                    console.output(repo.githubReadable.consoleText() + " [Fetched]".consoleText(.info))
                }
            case .cloning:
                console.output(repo.githubReadable.consoleText() + " [Cloned]".consoleText(.success))
            }
        }
    }

    func removing(repository: String) {
        console.output("Removing " + repository.consoleText(.warning) + "...")
    }

    func managedDependenciesDidUpdate(_ dependencies: AnySequence<ManagedDependency>) {
        print(#function)
    }
}

extension String {
    var githubReadable: String {
        return replacingOccurrences(of: "https://github.com/", with: "").replacingOccurrences(of: ".git", with: "")
    }
}
