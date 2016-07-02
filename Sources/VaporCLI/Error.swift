public enum Error: ErrorProtocol {
    case noExecutable
    case noCommand
    case commandNotFound
    case general(String)
    case shell(Int)
    case cancelled
}
