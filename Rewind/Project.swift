import ProjectDescription

let project = Project(
    name: "Rewind",
    settings: .settings(
        base: ["IPHONEOS_DEPLOYMENT_TARGET": "18.0"]
    ),
    targets: [
        .target(
            name: "Rewind",
            destinations: .iOS,
            product: .app,
            bundleId: "io.tuist.Rewind",
            infoPlist: .extendingDefault(
                with: [
                    "NSPhotoLibraryUsageDescription": "You can save any rewinds to your gallery!",
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
                .project(target: "Domain", path: "Modules/Domain"),
                .project(target: "Base", path: "Modules/Base"),
                .project(target: "AccessibilitySupport", path: "Modules/AccessibilitySupport")
            ],
            settings: .settings(
                base: [
                    "ASSETCATALOG_COMPILER_APPICON_NAME": "RewindLight",
                    "ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS": "YES",
                ]
            )
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
        .target(
            name: "RewindUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "io.tuist.RewindUITests",
            infoPlist: .default,
            sources: ["Rewind/UITests/**"],
            resources: [],
            dependencies: [
                .target(name: "Rewind"),
                .external(name: "Vapor")
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: "Rewind",
            shared: true,
            buildAction: .buildAction(targets: ["Rewind"]),
            testAction: .testPlans(["Rewind/UITests/UITestPlan.xctestplan"]),
            runAction: .runAction(executable: "Rewind")
        )
    ],
    additionalFiles: [
        "Rewind/UITests/UITestPlan.xctestplan",
    ]
)
