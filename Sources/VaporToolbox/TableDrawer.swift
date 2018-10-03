import Vapor

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
