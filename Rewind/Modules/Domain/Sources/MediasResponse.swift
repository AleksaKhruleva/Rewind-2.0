import SwiftUI
import PhotosUI

public struct MediasResponseItem: Codable {
    public let isFavourite: Bool
    public let memory: MediaItem
    public let tags: [String]
}

public struct MediasResponse: Codable {
    public let memories: [MediasResponseItem]
}
