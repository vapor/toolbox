import Globals
import Foundation

let cloudBaseUrl = "https://api.v2.vapor.cloud/v2/"
let gitUrl = cloudBaseUrl.trailingSlash + "git"
let gitSSHKeysUrl = gitUrl.trailingSlash + "keys"
let authUrl = cloudBaseUrl.trailingSlash + "auth"
let resetUrl = authUrl.trailingSlash + "reset"
let userUrl = authUrl.trailingSlash + "users"
let loginUrl = userUrl.trailingSlash + "login"
let meUrl = userUrl.trailingSlash + "me"

let applicationsUrl = appsUrl.trailingSlash + "applications"
func environmentUrl(with app: CloudApp) -> String {
    return applicationsUrl.trailingSlash
        + app.id.uuidString.trailingSlash
        + "environments"
}

public func replicasUrl(with env: CloudEnv) -> String {
    return environmentsUrl.trailingSlash
        + env.id.uuidString.trailingSlash
        + "replicas"
}

public func logsUrl(with replica: CloudReplica) -> String {
    return appsUrl.trailingSlash
        + "replicas".trailingSlash
        + replica.id.uuidString.trailingSlash
        + "logs"
}

let appsUrl = cloudBaseUrl.trailingSlash + "apps"
let environmentsUrl = appsUrl.trailingSlash + "environments"
let organizationsUrl = authUrl.trailingSlash + "organizations"
let regionsUrl = appsUrl.trailingSlash + "regions"
let plansUrl = appsUrl.trailingSlash + "plans"
let productsUrl = appsUrl.trailingSlash + "products"
let activitiesUrl = cloudBaseUrl.trailingSlash + "activity/activities"
let commandsUrl = appsUrl.trailingSlash + "commands"
public func commandsWssUrl(id: UUID, token: Token) -> String {
    return "wss://service.v2.vapor.cloud/v2/replica/command/logs/" + id.uuidString + "?token=" + token.key
}
