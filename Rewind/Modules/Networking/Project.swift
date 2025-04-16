import ProjectDescription
import ProjectDescriptionHelpers

let networkingProject = Project.featureFramework(
    name: "Networking",
    dependencies: [
        .project(target: "UIComponents", path: "../UIComponents"),
        .external(name: "Moya")
    ]
)
