import HTTP
import Vapor
import Foundation

public let applicationApi = ApplicationApi()

public struct Application: NodeInitializable {
    public let id: UUID
    public let name: String
    public let projectId: UUID
    public let repo: String

    public init(node: Node) throws {
        id = try node.get("id")
        name = try node.get("name")
        projectId = try node.get("project.id")
        repo = try node.get("repoName")
    }
}

public final class ApplicationApi {
    internal static let base = "https://application-api-staging.vapor.cloud/application"
    internal static let applications = "\(base)/applications"
}

extension ApplicationApi {
    // TODO: git expects ssh url, ie: git@github.com:vapor/vapor.git
    public func create(for project: Project, repo: String, git: String, name: String, with token: Token) throws -> Application {
        let request = try Request(method: .post, uri: ApplicationApi.applications)
        request.access = token

        var json = JSON([:])
        try json.set("project.id", project.id.uuidString)
        try json.set("repoName", repo)
        try json.set("gitUrl", git)
        try json.set("name", name)
        request.json = json

        let response = try client.respond(to: request)
        return try Application(node: response.json)
    }
}
