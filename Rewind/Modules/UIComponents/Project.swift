import ProjectDescription
import ProjectDescriptionHelpers

let uiComponentsProject = Project.featureFramework(
    name: "UIComponents",
    resources: ["Resources/**"],
    infoPlist: .extendingDefault(with: [
        "UIAppFonts": [
            "Fonts/AdvertisingScriptBold.ttf"
        ]
    ]),
    dependencies: [
        .project(target: "Base", path: "../Base"),
        .project(target: "AccessibilitySupport", path: "../AccessibilitySupport")
    ]
)
