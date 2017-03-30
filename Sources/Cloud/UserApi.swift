import JSON
import Vapor
import HTTP

let middleware = [AuthorizationMiddleware()]

extension AdminApi {
    public final class UserApi {
        public func createAndLogin(
            email: String,
            pass: String,
            firstName: String,
            lastName: String,
            organization: String,
            image: String?
            ) throws -> (user: User, token: Token) {
            try create(
                email: email,
                pass: pass,
                firstName: firstName,
                lastName: lastName,
                organization: organization,
                image: image
            )
            let token = try adminApi.user.login(email: email, pass: pass)
            let user = try adminApi.user.get(with: token)
            return (user, token)
        }

        @discardableResult
        public func create(email: String, pass: String, firstName: String, lastName: String, organization: String, image: String?) throws -> Response {
            var json = JSON([:])
            try json.set("email", email)
            try json.set("password", pass)
            try json.set("name.first", firstName)
            try json.set("name.last", lastName)
            try json.set("organization.name", organization)
            if let image = image {
                try json.set("image", image)
            }

            let request = try Request(method: .post, uri: usersEndpoint)
            request.json = json

            return try client.respond(to: request, through: middleware)
        }

        public func login(email: String, pass: String) throws -> Token {
            var json = JSON([:])
            try json.set("email", email)
            try json.set("password", pass)

            let request = try Request(method: .post, uri: loginEndpoint)
            request.json = json
            let response = try client.respond(to: request)
            guard
                let access = response.json?["accessToken"]?.string,
                let refresh = response.json?["refreshToken"]?.string
                else { throw "Bad response to login: \(response)" }

            return Token(access: access, refresh: refresh)
        }

        public func get(with token: Token) throws -> User {
            let request = try Request(method: .get, uri: meEndpoint)
            request.access = token

            let response = try client.respond(to: request)
            return try User(node: response.json)
        }
    }
}
