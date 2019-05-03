import ConsoleKit

struct Test: Command {
    struct Signature: CommandSignature {}
    let signature = Signature()
    let help: String? = "quick tests. probably don't call this. you shouldn't see it."

    func run(using ctx: Context) throws {
        let derivedLocation = try XcodeBuild.derivedDataLocation()
        print(derivedLocation)
        print("test ran")
    }
}
