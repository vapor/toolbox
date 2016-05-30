// String extensions

let whiteSpace = [Character(" "), Character("\n"), Character("\t"), Character("\r")]

enum ANSIColor: String {
    case black = "\u{001B}[0;30m"
    case red = "\u{001B}[0;31m"
    case green = "\u{001B}[0;32m"
    case yellow = "\u{001B}[0;33m"
    case blue = "\u{001B}[0;34m"
    case magenta = "\u{001B}[0;35m"
    case cyan = "\u{001B}[0;36m"
    case white = "\u{001B}[0;37m"
    case reset = "\u{001B}[0;0m"
}

extension String {
    func trim(trimCharacters: [Character] = whiteSpace) -> String {
        // while characters
        var mutable = self
        while let next = mutable.characters.first where trimCharacters.contains(next) {
            mutable.remove(at: mutable.startIndex)
        }
        while let next = mutable.characters.last where trimCharacters.contains(next) {
            mutable.remove(at: mutable.index(before: mutable.endIndex))
        }
        return mutable
    }
}

extension String {
    func centerTextBlock(width: Int, paddingCharacter: Character = " ") -> String {
        // Split the string into lines
        var lines = characters.split(separator: Character("\n")).map(String.init)

        // Make sure there's more than one line
        guard lines.count > 0 else {
            return ""
        }

        // Find the longest line
        var longestLine = 0
        for line in lines {
            if line.characters.count > longestLine {
                longestLine = line.characters.count
            }
        }

        // Calculate the padding and make sure it's greater than or equal to 0
        let padding = max(0, (width - longestLine) / 2)

        // Apply the padding to each line
        for i in 0..<lines.count {
            for _ in 0..<padding {
                lines[i].insert(paddingCharacter, at: startIndex)
            }
        }

        return lines.joined(separator: "\n")
    }

    #if os(Linux)
    func hasPrefix(_ str: String) -> Bool {
    let strGen = str.characters.makeIterator()
    let selfGen = self.characters.makeIterator()
    let seq = zip(strGen, selfGen)
    for (lhs, rhs) in seq where lhs != rhs {
    return false
    }
    return true
    }

    func hasSuffix(_ str: String) -> Bool {
    let strGen = str.characters.reversed().makeIterator()
    let selfGen = self.characters.reversed().makeIterator()
    let seq = zip(strGen, selfGen)
    for (lhs, rhs) in seq where lhs != rhs {
    return false
    }
    return true
    }
    #endif

    func colored(with colors: [Character: ANSIColor], default defaultColor: ANSIColor = .reset) -> String {
        // Check the string is long enough
        guard characters.count > 0 else {
            return ""
        }

        // Create a new string
        var newString = ""

        // Add the string to the new string and color it
        var currentColor: ANSIColor = defaultColor
        for character in characters {
            // Check if there is a new color for this character than the one before
            if (colors[character] ?? defaultColor) != currentColor {
                currentColor = colors[character] ?? defaultColor // Update the current color
                newString += currentColor.rawValue // Add the color the new string
            }

            newString += String(character) // Add the character to the string
        }

        // Reset the colors
        newString += ANSIColor.reset.rawValue

        return newString
    }

    func colored(with color: ANSIColor) -> String {
        return color.rawValue + self + ANSIColor.reset.rawValue
    }
}
