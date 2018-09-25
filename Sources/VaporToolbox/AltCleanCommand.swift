import Vapor

/// Cleans temporary files created by Xcode and SPM.
struct AltCleanCommand: Command {
    /// See `Command`.
    var arguments: [CommandArgument] = []

    /// See `Command`.
    var options: [CommandOption] = [
        .flag(name: "update", short: "u", help: [
            "Cleans the Package.resolved file if it exists",
            "This is equivalent to doing `swift package update`"
        ])
    ]

    /// See `Command`.
    var help: [String] = ["Cleans temporary files."]

    /// See `Command`.
    func run(using ctx: CommandContext) throws -> Future<Void> {
        let cleaner = try Cleaner(ctx: ctx)
        try cleaner.run()
        return .done(on: ctx.container)
    }
}

class Cleaner {
    let ctx: CommandContext
    let cwd: String
    let files: String

    var operations: [String: CleanResult] = [:]

    init(ctx: CommandContext) throws {
        self.ctx = ctx
        let cwd = try Shell.cwd()
        self.cwd = cwd
        self.files = try Shell.allFiles(in: cwd)
    }

    func run() throws {
        var ops: [String: () throws -> CleanResult] = [:]
        #if os(macOS)
        ops["xcodeproj"] = cleanXcode
        ops["DerivedData"] = cleanDerived
        #endif
        ops[".build"] = cleanBuildFolder
        ops["Package.resolved"] = cleanPackageResolved

        var rows: [[ConsoleText]] = []
        for (name, op) in ops {
            do {
                let result = try op()
                rows.append([
                    result.symbol,
                    name.consoleText(),
                    result.report
                ])
            } catch {
                rows.append([
                    CleanResult.failure.symbol,
                    name.consoleText(),
                    error.localizedDescription.consoleText()
                ])
            }
        }

        let drawer = TableDrawer(rows: rows)
        let table = drawer.drawTable()
        ctx.console.output(table)
    }

    private func cleanPackageResolved() throws -> CleanResult {
        guard files.contains("Package.resolved") else { return .notNecessary }
        if ctx.options["update"]?.bool == true {
            try Shell.delete("Package.resolved")
            return .success
        } else {
            return .ignored("      use [--update,-u] flag to remove this file during clean")
        }
    }

    private func cleanBuildFolder() throws -> CleanResult {
        guard files.contains(".build") else { return .notNecessary }
        try Shell.delete(".build")
        return .success
    }

    private func cleanXcode() throws -> CleanResult {
        guard files.contains(".xcodeproj") else { return .notNecessary }
        try Shell.delete("*.xcodeproj")
        return .success
    }

    // TODO: If found DerivedData at least once, assume relative enabled
    private func cleanDerived() throws -> CleanResult {
        let derivedData = cwd.finished(with: "/").appending("DerivedData")
        if FileManager.default.fileExists(atPath: derivedData) {
            try Shell.delete(derivedData)
            return .success
        } else {
            try informDerivedData()
            return .notNecessary
        }
    }

    /*
     - should we also delete core data at user location, main folder
     - how to detect where it is
     - save defaults to avoid duplicating this
     */
    private func informDerivedData() throws {
        ctx.console.output("warning: ".consoleText(.warning) + "no ./DerivedData folder detected")
        ctx.console.output("         enable relative derived data in Xcode > Preferences > Locations > Derived Data")
        ctx.console.output("set to: " + "Relative".consoleText(.success))
        ctx.console.output("ensure text box is set to: " + "DerivedData".consoleText(.success))

        let gitignore = try Shell.readFile(path: ".gitignore")
        guard !gitignore.contains("DerivedData") else { return }
        ctx.console.output("")
        ctx.console.output("warning: ".consoleText(.warning) + "Please add DerivedData to your .gitignore")
        ctx.console.output("or it will be tracked by .git after making this change.")

        guard ctx.console.confirm("Would you like me to do this now?") else { return }
        let new = gitignore.finished(with: "\n") + "DerivedData\n"
        try Shell.bash("echo \"\(new)\" >> .gitignore")
        ctx.console.output("\n")
        ctx.console.output("Updated .gitignore".consoleText(.success))
    }
}

enum CleanResult {
    case failure, success, notNecessary, ignored(String)

    var symbol: ConsoleText {
        switch self {
        case .failure:
            return "x".consoleText(.init(color: .red))
        case .success:
            return "✓".consoleText(.init(color: .green))
        case .notNecessary:
            return "•".consoleText(.init(color: .green))
        case .ignored(_):
            return "o".consoleText(.init(color: .yellow))
        }
    }

    var report: ConsoleText {
        switch self {
        case .failure:
            return "something went wrong"
        case .success:
            return "cleaned file"
        case .notNecessary:
            return "nothing to clean"
        case .ignored(let msg):
            return msg.consoleText()
        }
    }
}

extension Console {
    func printBox(box: [[ConsoleText]]) {
//        +------+--------+----+
//        |      |        |    |
    }
}

public func drawTable(with ctx: CommandContext) {
    let zero: [ConsoleText] = [
        "x",
        "xcodeproj",
        "removed"
    ]
    let one: [ConsoleText] = [
        "o",
        "Package.resolved",
        "use [--update,-u] flag to remove this file during clean"
    ]
    let two: [ConsoleText] = [
        "•",
        ".build",
        "nothing to clean"
    ]

    let drawer = TableDrawer(rows: [zero, one, two])
    let table = drawer.drawTable()
    ctx.console.output(table)
}

class TableDrawer {
    let rows: [[ConsoleText]]
    init(rows: [[ConsoleText]]) {
        self.rows = rows
    }

    lazy var numberOfRows: Int = {
        return rows.count
    }()

    lazy var numberOfColumns: Int = {
        var longest = 0
        for row in rows {
            guard row.count > longest else { continue }
            longest = row.count
        }
        return longest
    }()

    func widthOfColumn(at idx: Int) -> Int {
        var longest = 0
        for row in rows {
            guard let column = row[safe: idx] else { continue }
            guard column.length > longest else { continue }
            longest = column.length
        }
        return longest + 2 // pad 1 each side
    }

    func drawTable() -> ConsoleText {
        let lines = drawLines().map { $0 + "\n" }

        var table: ConsoleText = ""
        for line in lines {
            table += line
        }
        return table
    }

    private func drawLines() -> [ConsoleText] {
        var lines: [ConsoleText] = []
        let border = drawBorder()
        lines.append(border)
        lines += rows.map(drawRow)
        lines.append(border)
        return lines
    }

    func drawRow(with row: [ConsoleText]) -> ConsoleText {
        var drawn: ConsoleText = "|"

        for idx in 0..<numberOfColumns {
            let column = row[safe: idx]
            let desiredWidth = widthOfColumn(at: idx)
            var padded = column.flatMap { " " + $0 + " " } ?? " "
            while padded.length < desiredWidth {
                padded += " "
            }
            drawn += padded + "|"
        }

        return drawn
    }

    func drawBorder() -> ConsoleText {
        var columnPads: [ConsoleText] = []
        for i in 0..<numberOfColumns {
            let width = widthOfColumn(at: i)
            let pad = width.repeat(char: "-")
            let text = pad.consoleText()
            columnPads.append(text)
        }

        var border: ConsoleText = "+"
        columnPads.forEach { pad in
            border += pad
            border += "+"
        }
        return border
    }
}

extension ConsoleText {
    var length: Int {
        return description.count
    }
}

extension Int {
    func `repeat`(char: Character) -> String {
        let chars = [Character](repeating: char, count: self)
        return String(chars)
    }
}

extension Array where Element == ConsoleText {
    var longest: Index {
        var val = 0
        for row in self {
            guard row.count > val else { continue }
            val = row.count
        }
        return val
    }
}

extension Array {
    subscript(safe idx: Int) -> Element? {
        guard idx < count else { return nil }
        return self[idx]
    }
}

/*

 +---+------------------+---------------------------------------------------------+
 | x | xcodeproj        | removed                                                 |
 | o | Package.resolved | use [--update,-u] flag to remove this file during clean |
 | • | .build           | nothing to clean                                        |
 +---+------------------+---------------------------------------------------------+



+----------------------------------+---------+------------------------+----------------+
|               Col1               |  Col2   |          Col3          | Numeric Column |
+----------------------------------+---------+------------------------+----------------+
| Value 1                          | Value 2 | 123                    |           10.0 |
| Separate                         | cols    | with a tab or 4 spaces |       -2,027.1 |
| This is a row with only one cell |         |                        |                |
+----------------------------------+---------+------------------------+----------------+

*/

//extension String {
//    public static var plain: ConsoleStyle { return .init(color: nil) }
//
//    /// Green text with no background.
//    public static var success: ConsoleStyle { return .init(color: .green) }
//
//    /// Light blue text with no background.
//    public static var info: ConsoleStyle { return .init(color: .cyan) }
//
//    /// Yellow text with no background.
//    public static var warning: ConsoleStyle { return .init(color: .yellow) }
//
//    /// Red text with no background.
//    public static var error: ConsoleStyle { return .init(color: .red) }
//}
