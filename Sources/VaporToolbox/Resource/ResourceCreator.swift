import ConsoleKit
import Foundation

struct ResourceCreator {
  let console: Console
  let modelName: String
  let modelFile: String
  let modelMigrationFile: String
  let modelControllerFile: String
  let force: Bool
  let cwd: String

  init(
    console: Console, modelName: String, modelFile: String, modelMigrationFile: String,
    modelControllerFile: String, force: Bool = false
  ) {
    self.console = console
    self.modelName = modelName
    self.modelFile = modelFile
    self.modelMigrationFile = modelMigrationFile
    self.modelControllerFile = modelControllerFile
    self.force = force

    self.cwd = FileManager.default.currentDirectoryPath
  }

  func execute() {
    console.output("Generating resource...")
    generateModelFile()
    generateMigrationFile()
    generateControllerFile()
  }

  private func generateModelFile() {
    let modelDirectory = cwd.appendingPathComponents("Sources/App/Models")
    let modelOutputPath = modelDirectory.appendingPathComponents("\(modelName).swift")

    process(at: modelDirectory, to: modelOutputPath, with: modelFile)

  }

  private func generateMigrationFile() {
    let migrationDirectory = cwd.appendingPathComponents("Sources/App/Migrations")
    let migrationOutputPath = migrationDirectory.appendingPathComponents("Create\(modelName).swift")

    process(at: migrationDirectory, to: migrationOutputPath, with: modelMigrationFile)

  }

  private func generateControllerFile() {
    let controllerDirectory = cwd.appendingPathComponents("Sources/App/Controllers")
    let controllerOutputPath = controllerDirectory.appendingPathComponents(
      "\(modelName)Controller.swift")

    process(at: controllerDirectory, to: controllerOutputPath, with: modelControllerFile)
  }

  private func process(at directory: String, to file: String, with content: String) {

    if !isDirectoryExist(at: directory) {
      createDirectory(at: directory)
    }

    if !isFileExist(at: file) {
      createFile(at: file, with: content)
    } else if force {
      createFile(at: file, with: content)
    } else {
      console.warning("Resource file already exists at \(file)")
    }
  }

  private func isDirectoryExist(at path: String) -> Bool {
    guard FileManager.default.fileExists(atPath: path) else {
      return false
    }

    return true
  }

  private func createDirectory(at path: String) {
    do {
      try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
    } catch {
      console.error("Error creating directory: \(error.localizedDescription)")
    }
  }

  private func isFileExist(at path: String) -> Bool {
    guard FileManager.default.fileExists(atPath: path) else {
      return false
    }

    return true
  }

  private func createFile(at path: String, with file: String) {
    do {
      try file.write(toFile: path, atomically: true, encoding: .utf8)
      console.output("Resource file created at \(path)")
    } catch {
      console.error("Error creating resourse file: \(error.localizedDescription)")
    }
  }
}
