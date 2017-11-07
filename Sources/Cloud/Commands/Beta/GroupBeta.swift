@_exported import Console
import Foundation

public func groupBeta(_ console: ConsoleProtocol) throws -> Group {
    // create api factories
    let clientFactory = ClientFactory<EngineClient>()
    let cloudFactory = try CloudAPIFactory(
        baseURL: cloudURL,
        clientFactory
    )
    
    let addons = Group(id: "addon", commands: [
        AddonS3(console, cloudFactory),
        ], help: [
            "Addons to your application"
        ])
    
    let replicas = Group(id: "replicas", commands: [
        Resize(console, cloudFactory),
        Scale(console, cloudFactory)/*,
        Restart(console, cloudFactory)*/
        ], help: [
            "Manage your replicas (Resize, Scale etc.)"
        ])
    
    return Group(
        id: "cloud-beta",
        commands: [
            replicas/*,
            addons*/
        ],
        help: [
            "[BETA!] Commands for interacting with Vapor Cloud."
        ]
    )
}
