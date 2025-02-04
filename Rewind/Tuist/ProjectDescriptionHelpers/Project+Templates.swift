import ProjectDescription

extension Project {
    public static func featureFramework(name: String, dependencies: [TargetDependency] = []) -> Project {
        return Project(
            name: name,
            targets: [
                .target(
                    name: name,
                    destinations: .iOS,
                    product: .framework,
                    bundleId: "io.tuist.\(name)",
                    deploymentTargets: .iOS("17.0"),
//                    infoPlist: "\(name).plist",
                    sources: ["Sources/**"],
                    dependencies: dependencies
                )
            ]
        )
    }
}
