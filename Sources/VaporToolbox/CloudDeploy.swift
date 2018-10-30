import Vapor

struct CloudDeploy: MyCommand {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = []

    /// See `Command`.
    var help: [String] = ["Deploys a Vapory Project"]

    /// See `Command`.
    func trigger(with ctx: CommandContext) throws {
        let runner = CloudDeployRunner(ctx: ctx)
        try runner.run()
    }
}

struct CloudDeployRunner {
    let ctx: CommandContext

    func run() throws {
        // Ensure logged in
        let token = try Token.load()

        // Get App
        let app = try ctx.detectCloudApp()

        // Get Env
        let appEnvsUrl = applicationsUrl.trailSlash
            + app.id.uuidString.trailSlash
            + "environments"
        let envAccess = CloudEnv.Access(with: token, baseUrl: appEnvsUrl)
        let envs = try envAccess.list()
        let env = ctx.console.choose("Which Env?", from: envs) { env in
            return env.slug.consoleText()
        }

        // Confirm Git Status 

//        let access = CloudApp.Access(with: token, baseUrl: applicationsUrl)
//        let apps = try access.list()
//        let app = ctx.console.choose("Which App?", from: apps) { app in
//            return app.name.consoleText()
//        }
//        let appEnvsUrl = applicationsUrl.trailSlash + app.id.uuidString.trailSlash + "environments"
//        let envAccess = CloudEnv.Access(with: token, baseUrl: appEnvsUrl)
//        let envs = try envAccess.list()
//        let env = ctx.console.choose("Which Env?", from: envs) { env in
//            return env.slug.consoleText()
//        }
//
//
//        let deployAccess = CloudEnv.Access(with: token, baseUrl: environmentsUrl)
//        let updated = try deployAccess.update(
//            id: env.id.uuidString.trailSlash + "deploy",
//            with: [String: String]()
//        )
//        print(updated.activity?.id.uuidString ?? "<error>")
//
//        guard let activity = updated.activity else { throw "no activity returned" }
//        let wssUrl = "wss://api.v2.vapor.cloud/v2/activity/activities/\(activity.id.uuidString)/channel"
//        //    let wssUrl = "wss://sandbox.kaazing.net/echo"
//        print("Connecting to: \(wssUrl)")
//        let ws = try makeWebSocketClient(url: wssUrl).wait()
//        print("connected")
//        ws.onText { ws, text in
//            print("got text: \(text)")
//        }
//        try ws.onClose.wait()
//        print("Web socket closed")

        //
        //    let done = wss.flatMap { ws -> Future<Void> in
        //        print("Connected ws: \(ws)")
        //        // setup an on text callback that will print the echo
        //        ws.onText { ws, text in
        //            print("rec: \(text)")
        //            // close the websocket connection after we recv the echo
        ////            ws.close()
        //            sleep(3)
        //            ws.send("foo")
        //        }
        //
        //        ws.onBinary { ws, data in
        //            print("Some data tho: \(data)")
        //        }
        //
        //        // when the websocket first connects, send message
        ////        ws.send("hello, world!")
        //
        //        // return a future that will complete when the websocket closes
        //        return ws.onClose
        //    }
        //    try done.wait()
        //    print(done)
        ////    let deployUrl = environmentsUrl.trailSlash + env.id.uuidString.trailSlash + "deploy"
        ////    let deploy = [String: String].Access(with: token, baseUrl: deployUrl)
        ////    let updated = try deploy.update(id: env.id.uuidString, with: [String: String]())
        //    print(updated)
        //    print("")
        //    ctx.console.output("Deployed \(updated.slug)".consoleText())

    }
}




// git log --left-right --graph --cherry-pick --oneline cloud-api...origin/cloud-api
// Local is BEHIND remote
// > 8830125 (origin/cloud-api) more deploy work
// Local is AHEAD of remote
// < 5936b4f (HEAD -> cloud-api) more cloud commands
// < d352994 going to test alternative websocket

