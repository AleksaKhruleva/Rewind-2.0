import Foundation
import SwiftUI

public struct Member: Identifiable, Hashable {
    public let id: String
    public let name: String
    public var imageURL: String
    public let isOwner: Bool
    public let isUser: Bool
    
    public init(
        id: String,
        name: String,
        imageURL: String,
        isOwner: Bool = false,
        isUser: Bool = false
    ) {
        self.id = id
        self.name = name
        self.imageURL = imageURL
        self.isOwner = isOwner
        self.isUser = isUser
    }
}
