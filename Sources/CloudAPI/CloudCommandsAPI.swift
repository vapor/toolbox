import Foundation

fileprivate struct CloudRunCommandCreate: Encodable {
    let command: String
    let environmentID: UUID
}

public struct CloudRunCommandObject: Resource {
    public let id: UUID
}

public struct CloudRunCommandAPI {
    public let token: Token
    private let access: ResourceAccess<CloudRunCommandObject>

    public init(with token: Token) {
        self.token = token
        self.access = CloudRunCommandObject.Access(with: token, baseUrl: commandsUrl)
    }

    public func run(command: String, env: UUID) throws -> CloudRunCommandObject {
        let pack = CloudRunCommandCreate(command: command, environmentID: env)
        return try access.create(pack)
    }
}
