import ProjectDescription

extension Project {
    public static func featureFramework(
        name: String,
        resources: ResourceFileElements? = nil,
        infoPlist: InfoPlist = .default,
        dependencies: [TargetDependency] = []
    ) -> Project {
        return Project(
            name: name,
            targets: [
                .target(
                    name: name,
                    destinations: .iOS,
                    product: .framework,
                    bundleId: "io.tuist.\(name)",
                    deploymentTargets: .iOS("17.0"),
                    infoPlist: infoPlist,
                    sources: ["Sources/**"],
                    resources: resources,
                    dependencies: dependencies
                )
            ]
        )
    }
}
