import SwiftUI
import Base
import PhotosUI
import UIComponents
import Domain
import Networking

@MainActor @Observable
final class MediasUploadingViewModel {
    enum Intent {
        case importMedias([PhotosPickerItem])
        case removeMedia(LoadedMedia)
        case showMediaSettings(LoadedMedia)

        case createMedias
    }

    var similarSettigns: Bool
    var toggleDisabled: Bool
    var tags: [MediaTag]
    var loadedMedias: [LoadedMedia]
    var selection: [PhotosPickerItem]
    var showToast: (String) -> Void

    var viewingMedia: LoadedMedia?

    private let transformer: PhotosPickerItemTransformer

    private let backend: NetworkService

    init() {
        similarSettigns = false
        toggleDisabled = false
        tags = []
        loadedMedias = []
        selection = []
        showToast = { _ in }
        transformer = PhotosPickerItemTransformer()
        backend = NetworkService()
    }

    func dispatch(_ intent: Intent, onSuccess: @escaping () -> Void = {}) async {
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
                showToast(UIComponentsStrings.MediaUpload.error)
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
        case .createMedias:
            do {
                for loadedMedia in loadedMedias {
                    if let tokens = Tokens(), let groupId = GroupStorage.currentGroup?.id {
                        switch loadedMedia.content {
                        case let .image(image):
                            _ = try await backend.addMedia(
                                tokens: tokens,
                                groupId: groupId,
                                mediaType: "image",
                                mediaFile: image,
                                latitude: 23.1,
                                longitude: 22.2,
                                musicId: "id",
                                offset: 321,
                                duration: 123,
                                tags: loadedMedia.tags ?? []
                            )
                        case .video:
                            print()
                        }
                    }
                    onSuccess()
                }
            } catch {
                showToast("Can't load one of your images. You can try again later 😢")
            }
        }
    }

    func set(showToast: @escaping (String) -> Void) {
        self.showToast = showToast
    }
}
