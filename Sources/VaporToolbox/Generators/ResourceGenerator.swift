import Console

public final class ResourceGenerator: AbstractGenerator {

    override public var id: String {
        return "resource"
    }

    override public var signature: [Argument] {
        return super.signature + [
            Value(name: "properties", help: ["An optional list of properties for the resource Model class in the format variable:type (e.g. firstName:string lastname:string)"]),
            Value(name: "actions", help: ["An optional list of actions. Routes and Views will be created for each action."]),
            Option(name: "no-css", help: ["If true it doen't create a CSS file for the controller, defaults to true if 'actions' is empty."]),
            Option(name: "no-js", help: ["If true it doen't create a JavsScript file for the controller, defaults to true if 'actions' is empty."]),
        ]
    }

    override public func generate(arguments: [String]) throws {
        let argumentsToPassOn = arguments + ["--resource"]

        let modelGenerator = ModelGenerator(console: console)
        try modelGenerator.generate(arguments: argumentsToPassOn)

        let controllerGenerator = ControllerGenerator(console: console)
        try controllerGenerator.generate(arguments: argumentsToPassOn)
    }

}
