import ProjectDescription
import ProjectDescriptionHelpers

let networkingProject = Project.featureFramework(
    name: "Networking",
    dependencies: [
        .project(target: "Domain", path: "../Domain"),
        .project(target: "Base", path: "../Base"),
        .external(name: "Moya")
    ]
)
