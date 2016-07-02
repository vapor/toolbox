public protocol OptionValue {
    var bool: Bool? { get }
    var string: String? { get }
    var int: Int? { get }
    var double: Double? { get }
}

extension String: OptionValue {
    public var bool: Bool? {
        switch self.lowercased() {
        case "true", "yes", "y", "t", "1":
            return true
        case "false", "no", "n", "f", "0":
            return false
        default:
            return nil
        }
    }

    public var string: String? {
        return self
    }

    public var int: Int? {
        return Int(self)
    }

    public var double: Double? {
        return Double(self)
    }
}

extension Bool: OptionValue {
    public var bool: Bool? {
        return self
    }

    public var string: String? {
        switch self {
        case true:
            return "true"
        case false:
            return "false"
        }
    }

    public var int: Int? {
        switch self {
        case true:
            return 1
        case false:
            return 0
        }
    }

    public var double: Double? {
        switch self {
        case true:
            return 1.0
        case false:
            return 0.0
        }
    }
}