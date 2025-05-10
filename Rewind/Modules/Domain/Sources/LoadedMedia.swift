import SwiftUI
import PhotosUI

public struct LoadedMedia: Identifiable {
    public enum Content: Sendable {
      case image(UIImage)
      case video(url: URL, firstFrame: UIImage)
    }
    
    public let id: UUID
    public var content: Content
    public var photosPickerItem: PhotosPickerItem?
    
    public init(content: Content, photosPickerItem: PhotosPickerItem? = nil) {
        id = UUID()
        self.content = content
        self.photosPickerItem = photosPickerItem
    }
}
