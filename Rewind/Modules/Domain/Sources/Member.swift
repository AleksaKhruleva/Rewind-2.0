import Foundation
import SwiftUI

public struct Member: Identifiable, Hashable {
    public let id: Int
    public let name: String
    public let avatar: UIImage
    public let isOwner: Bool
    public let isUser: Bool

    public init(
        id: Int,
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
