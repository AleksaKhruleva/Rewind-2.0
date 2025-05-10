import ProjectDescription
import ProjectDescriptionHelpers

let networkingProject = Project.featureFramework(
    name: "Networking",
    dependencies: [
        .external(name: "Moya"),
        .project(target: "Domain", path: "../Domain"),
    ]
)
