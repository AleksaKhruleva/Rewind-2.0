import SwiftUI

// ВРЕМЕННО ТУТ
public struct Member: Identifiable, Hashable {
    public let id: UUID
    public let name: String
    let avatar: UIImage
    let isOwner: Bool
    let isUser: Bool
    
    init(
        id: UUID,
        name: String,
        avatar: UIImage,
        isOwner: Bool = false,
        isUser: Bool = false
    ) {
        self.id = id
        self.name = name
        self.avatar = avatar
        self.isOwner = isOwner
        self.isUser = isUser
    }
}

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
