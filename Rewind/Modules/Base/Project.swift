import ProjectDescription
import ProjectDescriptionHelpers

let baseProject = Project.featureFramework(
    name: "Base",
    dependencies: [
        .project(target: "Domain", path: "../Domain"),
    ]
)
