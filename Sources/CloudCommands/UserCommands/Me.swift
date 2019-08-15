import ConsoleKit
import CloudAPI
import Globals

struct Me: Command {
    struct Signature: CommandSignature {
        let all: Option = .all
    }
    
    /// See `Command`.
    let signature = Signature()
    
    let help = "shows information about logged in user."

    func run(using ctx: Context) throws {
        let token = try Token.load()
        let me = try UserApi().me(token: token)
        // name
        let name = me.firstName + " " + me.lastName
        ctx.console.output(name.consoleText())
        
        // email
        ctx.console.output(me.email.consoleText())
        
        // id (future others)
        guard ctx.flag(.all) else { return }
        ctx.console.output("user-id: ", newLine: false)
        ctx.console.output(me.id.uuidString.consoleText())
    }
}
