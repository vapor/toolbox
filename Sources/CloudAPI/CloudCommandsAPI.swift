import Foundation

fileprivate struct CloudRunCommandCreate: Encodable {
    let command: String
    let environmentID: UUID
}

public struct CloudRunCommand: Resource {
    let id: UUID
}

public struct CloudRunCommandAPI {
    public let token: Token
    private let access: ResourceAccess<CloudRunCommand>

    public init(with token: Token) {
        self.token = token
        self.access = CloudRunCommand.Access(with: token, baseUrl: commandsUrl)
    }

    public func run(command: String, env: UUID) throws -> CloudRunCommand {
        let pack = CloudRunCommandCreate(command: command, environmentID: env)
        return try access.create(pack)
    }
}
