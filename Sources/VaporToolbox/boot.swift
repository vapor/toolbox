import CloudCommands
import Globals
import NIOWebSocketClient
import ConsoleKit
import Foundation

var count = 0
public func testExample() throws {
    let client = WebSocketClient(eventLoopGroupProvider: .createNew)
    defer { try! client.syncShutdown() }
    try client.connect(host: "echo.websocket.org", port: 80, uri: "echo-test") { webSocket in
        webSocket.send(text: "Hello")
        webSocket.onText { webSocket, string in
            print("\(count): " + string)
            count += 1
            guard count > 5 else {
                sleep(2)
                webSocket.send(text: "ayo \(count)")
                return
            }
            webSocket.close(promise: nil)
        }
        }.wait()
}

var holder: WebSocketClient.Socket? = nil
public func _testExample() throws {
    let client = WebSocketClient(eventLoopGroupProvider: .createNew)
    defer { try! client.syncShutdown() }
    try client.connect(host: "api-activity.v2.vapor.cloud", port: 80, uri: "echo-test") { webSocket in
//        holder = webSocket
        print("connected")
        webSocket.onCloseCode({ (close) in
            print("closed w code: \(close)")
        })
        webSocket.send(text: "hello")
        webSocket.onText { webSocket, string in
            print("\(count): " + string)
            count += 1
            guard count > 5 else {
                sleep(2)
                webSocket.send(text: "ayo \(count)")
                return
            }
            webSocket.close(promise: nil)
        }
    }.wait()
}



final class Main: CommandGroup {
    struct Signature: CommandSignature {}
    
    let signature: Signature = Signature()
    
    let commands: Commands = [
        "clean": CleanCommand(),
        "linus-main": GenerateLinuxMain(),
        "cloud": CloudGroup(),
        "new": New(),
        "drop": PrintDroplet(),
        "test": Test(),
        "xcode": XcodeCommand(),
        "build": BuildCommand(),
        "leaf": LeafGroup()
    ]
    
    let help: String? = "main"
    
    func run(using ctx: CommandContext<Main>) throws {
        ctx.console.output("welcome to vapor.")
        ctx.console.output("use `vapor -h` to see commands")
    }
}

public func run() throws {
    var input = CommandInput(arguments: CommandLine.arguments)
    try Terminal().run(Main(), input: &input)
}
