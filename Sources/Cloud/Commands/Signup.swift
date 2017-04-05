
public final class Signup: Command {
    public let id = "signup"

    public let signature: [Argument] = []

    public let help: [String] = [
        "Creates a new Vapor Cloud user."
    ]

    public let console: ConsoleProtocol

    public init(console: ConsoleProtocol) {
        self.console = console
    }

    public func run(arguments: [String]) throws {
        let (email, pass) = try signup()
        try login(email: email, pass: pass)
    }

    private func signup() throws -> (email: String, password: String) {
        let email = console.ask("Email: ")
        let pass = console.ask("Password: ")
        let confirmed = console.ask("Confirm Password: ")
        guard pass == confirmed else {
            throw "Password mismatch, please try again."
        }
        let firstName = console.ask("First Name: ")
        let lastName = console.ask("Last Name: ")

        let defaultOrg = "\(firstName)'s Cloud"
        var organization = console.ask("Organization? (enter to use '\(defaultOrg)')")
        if organization.isEmpty {
            organization = defaultOrg
        }


        let bar = console.loadingBar(title: "Creating User")
        try bar.perform {
            _ = try adminApi.create(
                email: email,
                pass: pass,
                firstName: firstName,
                lastName: lastName,
                organizationName: organization,
                image: nil
            )
        }
        console.success("Welcome to Vapor Cloud.")
        console.print()

        return (email, pass)
    }

    private func login(email: String, pass: String) throws {
        guard console.confirm("Would you like to login now?") else { return }
        let login = Login(console: console)
        let args = ["--email=\(email)", "--pass=\(pass)"]
        try login.run(arguments: args)
    }
}
