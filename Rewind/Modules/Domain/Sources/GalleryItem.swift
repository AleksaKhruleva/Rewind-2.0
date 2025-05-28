import Foundation

public struct GalleryItem: Hashable, Identifiable {
    public var id: Int
    public var isFavourite: Bool
    public var tags: [String]
    public var memory: MediaItem
    
    public init(id: Int = -1, isFavourite: Bool, tags: [String], memory: MediaItem) {
        self.id = memory.id
        self.isFavourite = isFavourite
        self.tags = tags
        self.memory = memory
    }
}
