import SwiftUI
import Domain

// ВРЕМЕННО
public let membersForTest: [Member] = [
    Member(
        id: UUID(),
        name: "Claire",
        avatar: UIComponentsAsset.claireForlani.image,
        isOwner: true,
        isUser: true
    ),
    Member(
        id: UUID(),
        name: "Diana",
        avatar: UIComponentsAsset.diana.image
    ),
    Member(
        id: UUID(),
        name: "Jonny",
        avatar: UIComponentsAsset.johnnyDepp.image
    ),
    Member(
        id: UUID(),
        name: "Leo",
        avatar: UIComponentsAsset.leonardoDiCaprio.image
    ),
    Member(
        id: UUID(),
        name: "Marlo",
        avatar: UIComponentsAsset.marlonBrando.image
    ),
    Member(
        id: UUID(),
        name: "Matthew",
        avatar: UIComponentsAsset.matthewMcConaughey.image
    ),
]
