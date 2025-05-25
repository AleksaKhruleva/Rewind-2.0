import ProjectDescription
import ProjectDescriptionHelpers

let featuresProject = Project.featureFramework(
    name: "Features",
    dependencies: [
        .project(target: "UIComponents", path: "../UIComponents"),
        .project(target: "Networking", path: "../Networking"),
        .project(target: "AccessibilitySupport", path: "../AccessibilitySupport"),
        .project(target: "Domain", path: "../Domain")
    ]
)
