import ConsoleKit
import AsyncWebSocketClient
import Foundation
import CloudAPI

struct Test: Command {
    struct Signature: CommandSignature {
        @Argument(name: "url")
        var url: String
    }
    let signature = Signature()
    let help = "quick tests. probably don't call this. you shouldn't see it."

    func run(using ctx: CommandContext, signature: Signature) throws {
        ctx.console.output("testing...")
        let url = URL(string: signature.url)!
        print("connecting to: \(url)")
        let host = url.host!
//        let token = try Token.load()
        let uri = url.path + (url.query.flatMap { "?" + $0 } ?? "")
        print("h: \(host)\nuri: \(uri)")
        let client = WebSocketClient(eventLoopGroupProvider: .createNew)
        let connection = client.connect(host: host, port: 443, uri: uri, headers: [:]) { ws in
            print("connected")

            ws.onText { ws, text in
                print("on text " + text)
                sleep(1)
                ws.send(text: "yoyo")
            }

            ws.onBinary { _, _ in
                fatalError("not prepared to accept binary")
            }

            ws.onCloseCode { _ in
                print("closing")
                _ = ws.close()
            }
        }
        print("finished")
        try connection.wait()
        try client.syncShutdown()
    }
}
