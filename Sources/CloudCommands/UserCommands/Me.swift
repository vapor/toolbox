import ConsoleKit
import CloudAPI
import Globals

struct Me: Command {
    struct Signature: CommandSignature {
        @Flag(name: "all", short: "a", help: "show all data")
        var all: Bool
    }
    
    let help = "shows information about logged in user."

    func run(using ctx: CommandContext, signature: Signature) throws {
        let token = try Token.load()
        let me = try UserApi().me(token: token)
        // name
        let name = me.firstName + " " + me.lastName
        ctx.console.output(name.consoleText())
        
        // email
        ctx.console.output(me.email.consoleText())
        
        // id (future others)
        guard signature.all else { return }
        ctx.console.output("user-id: ", newLine: false)
        ctx.console.output(me.id.uuidString.consoleText())
    }
}
