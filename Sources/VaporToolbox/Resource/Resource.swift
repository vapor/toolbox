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

    // Checking if the project is a valid Swift Package
    guard FileManager.default.fileExists(atPath: package) else {
      throw ResourceError.notValidProject.localizedDescription
    }

    let scaffolder = ResourceScaffolder(console: context.console, modelName: name)

    // Generating the resource structures from given model name
    scaffolder.generate { model, migration, controller in

      let creator = ResourceCreator(
        console: context.console, modelName: name, modelFile: model, modelMigrationFile: migration,
        modelControllerFile: controller, force: force)

      // Executing the resource creation
      creator.execute()
    }

  }
}
