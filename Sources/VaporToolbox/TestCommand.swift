import ConsoleKit
import NIOWebSocketClient
import Foundation

struct Fooo {
    public enum Update {
        case connected
        case message(String)
        case close
    }
    
    private var wssUrl: URL {
        return URL(string: "wss://api-activity.v2.vapor.cloud/echo-test")!
    }
    
    private var host: String {
        return wssUrl.host!
    }
    private var uri: String {
        return wssUrl.path
    }
    
    public func listen(_ listener: @escaping (Update) -> Void) throws {
        let client = WebSocketClient(eventLoopGroupProvider: .createNew)
        defer { try! client.syncShutdown() }
        
        let connection = client.connect(host: host, port: 80, uri: uri, headers: [:]) { ws in
            print("connect")
            listener(.connected)
            ws.send(text: "one")
            ws.onText { ws, text in
                print("got text")
                listener(.message(text))
                sleep(2)
                ws.send(text: "yo")
            }
            
            ws.onBinary { ws, binary in
                print("got binary!!!")
            }
            
            ws.onCloseCode { _ in
                print("close")
                listener(.close)
            }
            
            ws.send(text: "hi")
        }
        print("will wait")
        try connection.wait()
        print("done waiting")
    }
}

struct Test: Command {
    struct Signature: CommandSignature {}
    let signature = Signature()
    let help: String? = "quick tests. probably don't call this. you shouldn't see it."

    func run(using ctx: Context) throws {
        print("testing..")
        try _testExample()
//
//        let foo = Fooo()
//        try foo.listen { (update) in
//            print("got update: \(update)")
//        }
    }
}
