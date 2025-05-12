import SwiftUI
import Base
import PhotosUI
import Domain

@MainActor @Observable
final class MediasUploadingViewModel {
    enum Intent {
        case importMedias([PhotosPickerItem])
        case removeMedia(LoadedMedia)
        case showMediaSettings(LoadedMedia)
    }
    
    var similarSettigns: Bool
    var toggleDisabled: Bool
    var tags: [String]
    var loadedMedias: [LoadedMedia]
    var selection: [PhotosPickerItem]
    var showToast: (String) -> Void
    
    var viewingMedia: LoadedMedia?
    
    let router: MediasUploadingRouter
    
    private let transformer: PhotosPickerItemTransformer
    
    init(router: MediasUploadingRouter) {
        similarSettigns = false
        toggleDisabled = false
        tags = []
        loadedMedias = []
        selection = []
        showToast = { _ in }
        transformer = PhotosPickerItemTransformer()
        self.router = router
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
        case let .showMediaSettings(media):
            viewingMedia = media
//            router.navigateToMediaSettings(media: media)
        }
    }
    
    func set(showToast: @escaping (String) -> Void) {
        self.showToast = showToast
    }
}
