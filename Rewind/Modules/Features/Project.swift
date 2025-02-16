import ProjectDescription
import ProjectDescriptionHelpers

let featuresProject = Project.featureFramework(
    name: "Features",
    dependencies: [.project(target: "UIComponents", path: "../UIComponents")]
)
