import ProjectDescription
import ProjectDescriptionHelpers

let uiComponentsProject = Project.featureFramework(
    name: "UIComponents",
    resources: ["Resources/**"],
    infoPlist: .extendingDefault(with: [
        "UIAppFonts": [
            "Fonts/AdvertisingScriptBold.ttf",
        ]
    ])
)
