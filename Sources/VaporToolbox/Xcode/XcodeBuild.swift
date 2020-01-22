import Foundation

struct XcodeBuild {
    static func derivedDataLocation(forProject project: String? = nil) throws -> String {
        var args: [String] = []
        if let project = project {
            args.append("-project")
            args.append(project)
        }
        args.append("-showBuildSettings")
        let raw = try Process.shell.run("xcodebuild", args)
        let buildSettings = raw.buildSettingsDictionary()
        guard let config = buildSettings["CONFIGURATION_BUILD_DIR"] else {
            throw "unable to find value for CONFIGURATION_BUILD_DIR"
        }

        return config.components(separatedBy: "/")
            .split(separator: "DerivedData")
            .dropLast()
            // in case this was somehow the name of a more global
            // directory nested under DerivedData
            .joined(separator: ["DerivedData"])
            .joined(separator: "/")
            + "/DerivedData" // append the last
    }
}

extension String {
    func buildSettingsDictionary() -> [String: String] {
        var buildSettings: [String: String] = [:]

        let lineItems = self.components(separatedBy: .newlines)
        lineItems.forEach { lineItem in
            let components = lineItem.split(
                separator: "=",
                maxSplits: 1,
                omittingEmptySubsequences: false
            )
            guard components.count == 2 else { return }
            let key = components[0].trimmingCharacters(in: .whitespaces)
            let val = components[1].trimmingCharacters(in: .whitespaces)
            buildSettings[key] = val
        }

        return buildSettings
    }
}
