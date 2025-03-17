enum ANSIColor: String {
    case black = "\u{001B}[30m"
    case red = "\u{001B}[31m"
    case green = "\u{001B}[32m"
    case yellow = "\u{001B}[33m"
    case blue = "\u{001B}[34m"
    case magenta = "\u{001B}[35m"
    case cyan = "\u{001B}[36m"
    case white = "\u{001B}[37m"
}

extension StringProtocol {
    func colored(_ color: ANSIColor) -> String {
        color.rawValue + self + "\u{001B}[0m"
    }
}

extension Character {
    func colored(_ color: ANSIColor?) -> String {
        guard let color = color else {
            return String(self)
        }
        return String(self).colored(color)
    }
}
