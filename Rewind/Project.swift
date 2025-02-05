import ProjectDescription

let project = Project(
    name: "Rewind",
    settings: .settings(
        base: ["IPHONEOS_DEPLOYMENT_TARGET": "17.0"]
    ),
    targets: [
        .target(
            name: "Rewind",
            destinations: .iOS,
            product: .app,
            bundleId: "io.tuist.Rewind",
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                ]
            ),
            sources: ["Rewind/Sources/**"],
            resources: ["Rewind/Resources/**"],
            dependencies: [
                .project(target: "UIComponents", path: "Modules/UIComponents"),
                .project(target: "Features", path: "Modules/Features"),
                .project(target: "Networking", path: "Modules/Networking"),
            ]
        ),
        .target(
            name: "RewindTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "io.tuist.RewindTests",
            infoPlist: .default,
            sources: ["Rewind/Tests/**"],
            resources: [],
            dependencies: [.target(name: "Rewind")]
        ),
    ]
)
