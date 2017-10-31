public final class DatabaseFeedbackFormat {
    
    init(_ console: ConsoleProtocol, _ info: FeedbackInfo) {
        guard info.status != "exit" else {
            do {
                exit(0)
            } catch {
                exit(1)
            }
        }
        
        switch(info.status) {
        case "error":
            console.error("[ Error ] " + info.message)
        case "warning":
            console.warning("[ Warning ] " + info.message)
        case "success":
            console.success("[ Success ] " + info.message)
        default:
            console.info("[ Info ] " + info.message)
        }
    }
    
}

