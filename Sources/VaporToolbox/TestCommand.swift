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
        let sock = Sock(signature.url)
        try sock.listen { update in
            switch update {
            case .connected:
                ctx.console.output("connect")
                sock.ws?.send(text: "heyyyyyyyy")
            case .message(let msg):
                ctx.console.output("got message: " + msg.consoleText())
            case .close:
                ctx.console.output("closedd")
            }
        }
    }
}

final class Sock {
    public enum Update {
        case connected
        case message(String)
        case close
    }

    private(set) var ws: WebSocketClient.Socket?

    private var wssUrl: URL

    private var host: String {
        return wssUrl.host!
    }
    private var uri: String {
        let query = wssUrl.query.flatMap { "?" + $0 } ?? ""
        return wssUrl.path + query
    }

    init(_ url: String) {
        wssUrl = URL(string: url)!
    }

    public func listen(_ listener: @escaping (Update) -> Void) throws {
        let client = WebSocketClient(eventLoopGroupProvider: .createNew)

        let connection = client.connect(host: host, port: 80, uri: uri, headers: [:]) { [weak self] ws in
            self?.ws = ws
            listener(.connected)

            ws.onText { ws, text in
                listener(.message(text))
            }

            ws.onBinary { _, _ in
                fatalError("not prepared to accept binary")
            }

            ws.onCloseCode { [weak self] _ in
                listener(.close)
                _ = ws.close()
                self?.ws = nil
            }
        }
        try connection.wait()
        try client.syncShutdown()
    }
}
