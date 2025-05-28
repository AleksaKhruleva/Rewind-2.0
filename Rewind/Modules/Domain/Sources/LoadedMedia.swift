import SwiftUI
import PhotosUI

public struct LoadedMedia: Hashable, Identifiable {
    public enum Content: Hashable, Sendable {
        case image(UIImage)
        case video(url: URL, firstFrame: UIImage)
    }

    public let id: UUID
    public var content: Content
    public var tags: [MediaTag]?
    public var photosPickerItem: PhotosPickerItem?
    public var videoEditingSettings: VideoEditingSettings?
    public var trackInfo: TrackInformation?

    public init(
        content: Content,
        photosPickerItem: PhotosPickerItem? = nil,
        videoEditingSettings: VideoEditingSettings? = nil
    ) {
        id = UUID()
        self.content = content
        self.photosPickerItem = photosPickerItem
        self.videoEditingSettings = videoEditingSettings
    }
}

public struct TrackInformation: Codable, Hashable {
    public let id: String
    public let startTime: Double
    public let duration: Double
    
    public init(
        id: String,
        startTime: Double,
        duration: Double
    ) {
        self.id = id
        self.startTime = startTime
        self.duration = duration
    }
}
