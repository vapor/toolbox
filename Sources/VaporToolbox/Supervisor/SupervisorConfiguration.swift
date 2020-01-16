// [program:hello]
// command=/home/vapor/hello/.build/release/Run serve --env production
// directory=/home/vapor/hello/
// user=vapor
// stdout_logfile=/var/log/supervisor/%(program_name)-stdout.log
// stderr_logfile=/var/log/supervisor/%(program_name)-stderr.log

struct SupervisorConfiguration {
    let program: String
    let attributes: Attributes

    struct Attributes: ExpressibleByDictionaryLiteral {
        typealias Key = String
        typealias Value = String

        let values: [(String, String)]

        init(dictionaryLiteral elements: (String, String)...) {
            self.values = elements
        }
    }

    func serialize() -> String {
        var lines = ["[program:\(self.program)]"]
        for (key, value) in self.attributes.values {
            lines.append("\(key)=\(value)")
        }
        return lines.joined(separator: "\n")
    }
}
