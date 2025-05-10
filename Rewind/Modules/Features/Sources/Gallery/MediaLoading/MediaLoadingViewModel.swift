import SwiftUI
import Base
import PhotosUI
import Domain

@MainActor @Observable
final class MediaLoadingViewModel {
    enum Intent {
        case importMedias([PhotosPickerItem])
        case removeMedia(LoadedMedia)
    }
    
    var similarSettigns: Bool
    var tags: [String]
    var loadedMedias: [LoadedMedia]
    var selection: [PhotosPickerItem]
    var showToast: (String) -> Void
    
    private let transformer: PhotosPickerItemTransformer
    
    init() {
        similarSettigns = false
        tags = []
        loadedMedias = []
        selection = []
        showToast = { _ in }
        transformer = PhotosPickerItemTransformer()
    }
    
    func dispatch(_ intent: Intent) async {
        switch intent {
        case let .importMedias(items):
            do {
                let importedPickerItemsSet = Set(loadedMedias.compactMap { $0.photosPickerItem })
                let itemsSet = Set(items)
                
                let newItems = itemsSet.subtracting(importedPickerItemsSet)
                let orderedNewItems = items.filter { newItems.contains($0) }
                
                for item in orderedNewItems {
                    let newItem = try await self.transformer.transform(source: item)
                    withAnimation {
                        self.loadedMedias += [newItem]
                    }
                }
            } catch {
                showToast("Can't load some of your medias 🫥")
            }
        case let .removeMedia(item):
            if let needed = item.photosPickerItem,
               let selectionItemIndex = selection.firstIndex(of: needed) {
                selection.tryRemove(at: selectionItemIndex)
            }
            
            withAnimation {
                if let index = loadedMedias.firstIndex(where: { $0.photosPickerItem == item.photosPickerItem }) {
                    loadedMedias.tryRemove(at: index)
                }
            }
        }
    }
    
    func set(showToast: @escaping (String) -> Void) {
        self.showToast = showToast
    }
}
