 import Vapor

 extension CommandOption {
     static let readableName: CommandOption = .value(
         name: "readable-name",
         short: "n",
         default: nil,
         help: ["The readable name to give your key."]
     )
     static let path: CommandOption = .value(
         name: "path",
         short: "p",
         default: nil,
         help: ["A custom path to they public key that should be pushed."]
     )
     static let key: CommandOption = .value(
         name: "key",
         short: "k",
         default: nil,
         help: ["Use this to pass the contents of your public key directly."]
     )
 }
