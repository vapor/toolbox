import HTTP
import Vapor

public final class AdminApi {
    internal static let base = "https://admin-api-staging.vapor.cloud/admin"
    internal static let usersEndpoint = "\(base)/users"
    internal static let loginEndpoint = "\(base)/login"
    internal static let meEndpoint = "\(base)/me"
    internal static let refreshEndpoint = "\(base)/refresh"
    internal static let organizationsEndpoint = "\(base)/organizations"
    internal static let projectsEndpoint = "\(base)/projects"

    // client
    internal static let client = EngineClient.self

    public let user = UserApi()
    public let access = AccessApi()
    public let organizations = OrganizationApi()
    public let projects = ProjectsApi()
}
