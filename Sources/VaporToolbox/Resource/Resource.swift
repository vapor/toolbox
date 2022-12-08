import ConsoleKit
import Foundation

struct Resource: AnyCommand {
  struct Signature: CommandSignature {
    @Argument(name: "name", help: "Name of resource.")
    var name: String

    @Flag(name: "force", help: "Overwrite existing resources.")
    var force: Bool
  }

  let help = """
    Generates a new resources.

    This command will generate a new resource with the given name. 
    The resource will be created in the current directory.

    example input:
    vapor resource User

    example output:
    ./Sources/App/Models/User.swift
    ./Sources/App/Controllers/UserController.swift
    ./Sources/App/Migrations/CreateUser.swift
    """

  func outputHelp(using context: inout CommandContext) {
    Signature().outputHelp(help: self.help, using: &context)
  }

  func run(using context: inout CommandContext) throws {
    let signature = try Signature(from: &context.input)
    let name =
      signature.name.isEmpty
      ? "Model"
      : signature.name
        .prefix(1)
        .uppercased()
        + signature.name
        .dropFirst()
    let force = signature.force
    let cwd = FileManager.default.currentDirectoryPath
    let package = cwd.appendingPathComponents("Package.swift")

    guard FileManager.default.fileExists(atPath: package) else {
      throw ResourceError.notValidProject.localizedDescription
    }

    let resource = ResourceScaffolder(console: context.console, modelName: name)

    resource.generate { model, migration, controller in
      //TODO: Check if file exists and ask to overwrite
    }

    let scaffolder = ResourceScaffolder(console: context.console, modelName: name)
    scaffolder.generate { model, migration, controller in
      let creator = ResourceCreator(
        console: context.console, modelName: name, modelFile: model, modelMigrationFile: migration,
        modelControllerFile: controller, force: force)
      creator.execute()
    }
  }
}

enum ResourceError: Error {
  case notValidProject

  var localizedDescription: String {
    switch self {
    case .notValidProject:
      return "No Package.swift found. Are you in a Vapor project?"
    }
  }
}
