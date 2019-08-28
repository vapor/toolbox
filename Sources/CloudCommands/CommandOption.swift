import ConsoleKit
import Globals

extension Option where Value == Int {
    static var lines: Option {
        let def = "200"
        return .init(name: "lines", short: "l", type: .value(default: def), help: "the number of lines to show, default '\(def)'.")
    }
}

extension Option where Value == String {
    static var email: Option {
        return .init(name: "email", short: "e", type: .value, help: "the email to use.")
    }
    static var password: Option {
        return .init(name: "password", short: "p", type: .value, help: "the password to use.")
    }
    static var firstName: Option {
        return .init(name: "first-name", short: "f", type: .value, help: "your first name.")
    }
    static var lastName: Option {
        return .init(name: "last-name", short: "l", type: .value, help: "your last name.")
    }
    static var org: Option {
        return .init(name: "org", short: "o", type: .value, help: "which organization to use.")
    }
    
    static var app: Option {
        return .init(name: "app", short: "a", type: .value, help: "the slug associated with your app.")
    }
    
    static var env: Option {
        return .init(name: "env", short: "e", type: .value, help: "the environment to use.")
    }
    static var branch: Option {
        return .init(name: "branch", short: "b", type: .value, help: "the branch to use, if other than app's default.")
    }
    
    static var readableName: Option {
        return .init(name: "readable-name", short: "n", type: .value, help: "a human readable name to use.")
    }
    
    static var path: Option {
        return .init(name: "path", short: "p", type: .value, help: "a custom path to use if desired.")
    }
    
    static var key: Option {
        return .init(name: "key", short: "k", type: .value, help: "use this to pass the contents of your public key directly.")
    }
}

extension Option where Value == Bool {
    static var all: Option {
        return .init(name: "all", short: "a", type: .flag, help: "include more data.")
    }
    static var showTimestamps: Option {
        return .init(name: "show-timestamps", short: "t", type: .flag, help: "if passed, should show timestamps.")
    }
    static var force: Option {
        return .init(name: "force", short: "f", type: .flag, help: "forces the operation. overwrites if necessary. you WILL lose overwritten data, this action is irreversible.")
    }
    static var push: Option {
        return .init(name: "push", short: "p", type: .flag, help: "push to cloud as well.")
    }
}

extension LosslessStringConvertible {
    static func convertOrFail(_ raw: String) -> Self {
        if let val = self.init(raw) { return val }
        else { fatalError("unable to convert \(raw) to '\(type(of: Self.self))'") }
    }
}

extension Option {
    var `default`: String? {
        guard case let .value(d) = self.optionType else { return nil }
        return d
    }
}

extension CommandContext {
    public func load<V: LosslessStringConvertible>(_ opt: Option<V>, _ message: String? = nil, secure: Bool = false) -> V {
        
        if let raw = self.rawOptions.value(opt) ?? opt.default {
            return V.convertOrFail(raw)
        }
        let msg = message ?? opt.name
        console.pushEphemeral()
        let answer = console.ask(msg.consoleText(), isSecure: secure)
        console.popEphemeral()
        return V.convertOrFail(answer)
    }
    
    public func flag(_ opt: Option<Bool>) -> Bool {
        return self.rawOptions.value(opt).flatMap(Bool.init) ?? false
    }
}

extension Dictionary where Key == String, Value == String {
    public func value<V: LosslessStringConvertible>(_ option: Option<V>) -> String? {
        return self[option.name]
    }
}
