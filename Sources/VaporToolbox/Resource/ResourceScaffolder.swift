import ConsoleKit
import Foundation

struct ResourceScaffolder {
  let console: Console
  let modelName: String

  init(console: Console, modelName: String) {
    self.console = console
    self.modelName = modelName.isEmpty ? "Model" : modelName
  }

  func generate(escaping: (String, String, String) -> Void) {
    console.output("Generating resource...")
    let model = generateModel()
    let migration = generateMigration()
    let controller = generateController()

    escaping(model, migration, controller)
  }

  private func generateModel() -> String {
    console.output("Generating model for \(modelName)...")

    let model =
      """
      import Fluent
      import Vapor

      final class \(modelName): Model, Content {
          static let schema = "\(modelName.lowercased())_table"

          @ID(key: .id)
          var id: UUID?

          // Add your fields here
          // Example:
        // @Field(key: "modelName")
        // var modelName: String

            init() {}

            init(id: UUID? = nil) {
                self.id = id
            }
        }
      """

    return model
  }

  private func generateController() -> String {
    console.output("Generating controller for \(modelName)Controller...")

    let endpoint = modelName.lowercased() + "s"
    let query = modelName.lowercased() + "ID"

    let controller =
      """
      import Vapor

      struct \(modelName)Controller: RouteCollection {
          func boot(routes: RoutesBuilder) throws {
              let \(endpoint) = routes.grouped(\(endpoint))
              \(endpoint).get(use: index)
              \(endpoint).post(use: create)
              \(endpoint).group(":\(query)") { \(modelName) in
                \(modelName).get(use: read)
                \(modelName).put(use: update)
                \(modelName).delete(use: delete)
              }
          }

            func index(req: Request) async throws -> [\(modelName)]> {
                throw Abort(.notImplemented)
            }

            func create(req: Request) async throws -> \(modelName)> {
                throw Abort(.notImplemented)
            }

            func read(req: Request) async throws -> \(modelName)> {
                guard let id = req.parameters.get("\(query)", as: UUID.self) else {
                    throw Abort(.badRequest)
                }

                throw Abort(.notImplemented)
            }

            func update(req: Request) async throws -> \(modelName)> {
                guard let id = req.parameters.get("\(query)", as: UUID.self) else {
                    throw Abort(.badRequest)
                }

                throw Abort(.notImplemented)
            }

            func delete(req: Request) async throws -> HTTPStatus {
                guard let id = req.parameters.get("\(query)", as: UUID.self) else {
                    throw Abort(.badRequest)
                }

                throw Abort(.notImplemented)
            }
      }
      """

    return controller
  }

  private func generateMigration() -> String {
    console.output("Generating migration for Create\(modelName)...")

    let schema = modelName.lowercased() + "_table"

    let migration =
      """
      import Fluent

      struct Create\(modelName): Migration {
          func prepare(on database: Database) -> EventLoopFuture<Void> {
              database.schema("\(schema)")
                  .id()
                  // Add fields here
                  // Example:
                  // .field("modelName", .string, .required)
                  .create()
          }

          func revert(on database: Database) -> EventLoopFuture<Void> {
              database.schema("\(schema)").delete()
          }
      }
      """

    return migration
  }
}
