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
