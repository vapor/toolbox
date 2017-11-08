public final class DatabaseLogSubscribe {
    
    public let console: ConsoleProtocol
    
    init(_ console: ConsoleProtocol) {
        self.console = console
    }
    
    public func subscribe(channel: String) throws {
        
        var waitingInQueue = console.loadingBar(title: "Contacting cluster")
        defer { waitingInQueue.fail() }
        waitingInQueue.start()
        
        var logsBar: LoadingBar?
        
        try CloudRedis.subscribeLog(channel: channel) { data in
            waitingInQueue.finish()
            
            switch data.status {
            case "start":
                logsBar = self.console.loadingBar(title: data.message)
                logsBar?.start()
            case "success":
                logsBar?.finish()
            case "error":
                logsBar?.fail()
                self.console.error("[ Error ] " + data.message)
                exit(0)
            default:
                logsBar?.finish()
                //exit(0)
            }
            
            if (data.finished) {
                //exit(0)
            }
        }
    }
    
}


