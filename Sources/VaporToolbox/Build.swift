import Console
import Foundation

public final class Build: Command {
    public let id = "build"

    public let signature: [Argument] = [
        Option(name: "run", help: ["Runs the project after building."]),
        Option(name: "clean", help: ["Cleans the project before building."]),
        Option(name: "mysql", help: ["Links MySQL libraries."]),
        Option(name: "debug", help: ["Builds with debug symbols."]),
        Option(name: "dylib", help: ["Forces all packages to generate dynamic libraries. This only needs to be executed once unless new libraries are added."])
    ]

    public let help: [String] = [
        "Compiles the application."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        // Run a clean if needed
        if arguments.options["clean"]?.bool == true {
            let clean = Clean(console: console)
            try clean.run(arguments: arguments)
        }

        // Fetch all the dependencies before building
        let fetch = Fetch(console: console)
        try fetch.run(arguments: [])
        
        // Add dynamic libraries to packages
        if arguments.flag("dylib") {
            try updatePackagesWithDyLib(arguments: arguments)
        }

        // Create list to add build flags to
        var buildFlags: [String] = []

        // Add appropriate MySQL flags
        if arguments.flag("mysql") {
            buildFlags += [
                "-Xswiftc",
                "-I/usr/local/include/mysql",
                "-Xlinker",
                "-L/usr/local/lib"
            ]
        }

        // Add debug flags if needed
        if arguments.flag("debug") {
            buildFlags += [
                "-Xswiftc",
                "-g"
            ]
        }
        
        // Show building status
        let buildBar = console.loadingBar(title: "Building Project")
        buildBar.start()

        // Add any other build flags
        for (name, value) in arguments.options {
            if ["clean", "run", "mysql", "debug"].contains(name) {
                continue
            }

            if name == "release" && value.bool == true {
                buildFlags += "--configuration release"
            } else {
                buildFlags += "--\(name)=\(value.string ?? "")"
            }
        }

        // Create command array
        var commandArray = ["swift", "build"]
        commandArray += buildFlags

        // Execute command
        let command = commandArray.joined(separator: " ")
        do {
            _ = try console.backgroundExecute(program: commandArray[0], arguments: commandArray.dropFirst(1).array)
            buildBar.finish()
        } catch ConsoleError.backgroundExecute(let code, let error) {
            buildBar.fail()
            console.print()
            console.info("Command:")
            console.print(command)
            console.print()
            console.info("Error (\(code)):")
            console.print(error)

            console.info("Toolchain:")
            let toolchain = try console.backgroundExecute(program: "which", arguments: ["swift"]).trim()
            console.print(toolchain)
            console.print()
            console.info("Help:")
            console.print("Join our Slack where hundreds of contributors")
            console.print("are waiting to help: http://slack.qutheory.io")
            console.print()

            throw ToolboxError.general("Build failed.")
        }
        
        // Create DyLib aliases
        if arguments.flag("dylib") {
            try writeDyLibAliases(arguments: arguments)
        }

        // Run the project
        if arguments.options["run"]?.bool == true {
            let args = arguments.filter { !["--clean", "--run"].contains($0) }
            let run = Run(console: console)
            try run.run(arguments: args)
        }
    }

    private func currentWorkingDirectory() -> String? {
        guard let cwd = getcwd(nil, Int(PATH_MAX)) else { return nil }
        defer { free(cwd) }
        guard let path = String(validatingUTF8: cwd) else { return nil }
        return path
    }
    
    private func packageDump(path: URL) throws -> [String: AnyObject] {
        let jsonData = try console.backgroundExecuteData(program: "swift", arguments: ["package", "dump-package", "--input", path.path])
        let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as! [String: AnyObject]
        return json
    }
    
    private func appendProduct(named productName: String, toPackage package: String) -> String {
        // Create text that will be appended
        let appendText =
            "let lib\(productName) = Product(name: \"\(productName)\", type: .Library(.Dynamic), modules: \"\(productName)\")\n" +
            "products.append(lib\(productName))\n"
        
        // Return new text, if doesn't exist already
        if !package.contains(appendText) {
            return package.appending(appendText)
        } else {
            return package
        }
    }
    
    private func updatePackagesWithDyLib(arguments: [String]) throws {
        // Create loading bar
        let processBar = console.loadingBar(title: "Processing Packages")
        processBar.start()
        
        do {
            // Get the project URL
            guard let projectPath = currentWorkingDirectory() else {
                throw ToolboxError.general("Could not get current working directory.")
            }
            let projectUrl = URL(fileURLWithPath: projectPath)
            
            // Find all the packages in the `Packages` folder
            // The folder is assumed to exist since Fetch is executed before this
            let packages = try FileManager.default.contentsOfDirectory(
                at: projectUrl.appendingPathComponent("Packages/"),
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
            
            // Process all the packages
            for packageUrl in packages {
                // Get the package dump
                let package = try packageDump(path: packageUrl)
                
                // Get the package contents
                let packageFileUrl = packageUrl.appendingPathComponent("Package.swift")
                var packageContents = try String(contentsOf: packageFileUrl, encoding: String.Encoding.utf8)
                packageContents += "\n" // Add new line to pad products
                
                if let targets = package["package.targets"] as? [[String: AnyObject]], targets.count > 0 { // Add product for every target
                    // Has targets
                    for target in targets {
                        // Get the name of the target
                        guard let name = target["name"] as? String else {
                            print("Could not get name for package target.")
                            continue
                        }
                        
                        // Append the product
                        packageContents = appendProduct(named: name, toPackage: packageContents)
                    }
                } else { // Just use name as the product
                    // Get the name of the package
                    guard let name = package["name"] as? String else {
                        print("Could not get name for package.")
                        continue
                    }
                    
                    // Append the product
                    packageContents = appendProduct(named: name, toPackage: packageContents)
                }
                
                // Write thew new package file
                try packageContents.write(to: packageFileUrl, atomically: true, encoding: String.Encoding.utf8)
            }
            
            // Finish the process
            processBar.finish()
        } catch {
            processBar.fail()
            console.print()
            console.info("Error:")
            console.print(error.localizedDescription)
            console.print()
            
            throw ToolboxError.general("Processing packages failed.")
        }
    }
    
    private func writeDyLibAliases(arguments: [String]) throws {
        // Create loading bar
        let processBar = console.loadingBar(title: "Creating DyLib Aliases")
        processBar.start()
        
        do {
            // Get the project URL
            guard let projectPath = currentWorkingDirectory() else {
                throw ToolboxError.general("Could not get current working directory.")
            }
            let projectUrl = URL(fileURLWithPath: projectPath)
            
            // Deal with DyLibs folder
            let dyLibsFolderURL = projectUrl.appendingPathComponent("DyLibs")
            var isDirectory: ObjCBool = ObjCBool(false)
            if FileManager.default.fileExists(atPath: dyLibsFolderURL.path, isDirectory: &isDirectory), isDirectory.boolValue { // Remove the DyLibs folder if it exists
                try FileManager.default.removeItem(at: dyLibsFolderURL)
            }
            try FileManager.default.createDirectory(at: dyLibsFolderURL, withIntermediateDirectories: false, attributes: nil) // Create/recreate the DyLibs folder
            
            // Get the build folder with the DyLibs
            let buildFolderPath: String
            if arguments.flag("release") {
                buildFolderPath = ".build/release"
            } else {
                buildFolderPath = ".build/debug"
            }
            
            // Find all DyLibs in the build folder
            let buildFolder = projectUrl.appendingPathComponent(buildFolderPath)
            let dylibFiles = try FileManager.default.contentsOfDirectory(
                at: buildFolder,
                includingPropertiesForKeys: nil,
                options: []
            ).filter { $0.pathExtension == "dylib" }
            
            // Create aliases for all the DyLibs in the DyLibs/ folder
            for dylibFile in dylibFiles {
                let alias = try dylibFile.bookmarkData(options: URL.BookmarkCreationOptions.suitableForBookmarkFile)
                let aliasTargetURL = dyLibsFolderURL.appendingPathComponent(dylibFile.lastPathComponent)
                try URL.writeBookmarkData(alias, to: aliasTargetURL)
            }
            
            // Finish the process
            processBar.finish()
        } catch {
            processBar.fail()
            console.print()
            console.info("Error:")
            console.print(error.localizedDescription)
            console.print()
            
            throw ToolboxError.general("Creating dynamic library aliases failed.")
        }
    }
}
