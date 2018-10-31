
extension String {
    internal var trailSlash: String { return finished(with: "/") }
}

let cloudBaseUrl = "https://api.v2.vapor.cloud/v2/"
let gitUrl = cloudBaseUrl.trailSlash + "git"
let gitSSHKeysUrl = gitUrl.trailSlash + "keys"
let authUrl = cloudBaseUrl.trailSlash + "auth"
let resetUrl = authUrl.trailSlash + "reset"
let userUrl = authUrl.trailSlash + "users"
let loginUrl = userUrl.trailSlash + "login"
let meUrl = userUrl.trailSlash + "me"

public let applicationsUrl = appsUrl.trailSlash + "applications"
public func environmentUrl(with app: CloudApp) -> String {
    return applicationsUrl.trailSlash
        + app.id.uuidString.trailSlash
        + "environments"
}

let appsUrl = cloudBaseUrl.trailSlash + "apps"
public let environmentsUrl = appsUrl.trailSlash + "environments"
let organizationsUrl = authUrl.trailSlash + "organizations"
let regionsUrl = appsUrl.trailSlash + "regions"
let plansUrl = appsUrl.trailSlash + "plans"
let productsUrl = appsUrl.trailSlash + "products"
let activitiesUrl = cloudBaseUrl.trailSlash + "activity/activities"
