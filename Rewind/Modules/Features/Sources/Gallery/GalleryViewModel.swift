import SwiftUI
import PhotosUI
import Base
import Domain
import UIComponents
import Networking

@MainActor @Observable
final class GalleryViewModel {
    enum Intent {
        case viewGallery
        case showMediasDialog
        case selectOneMedia(PhotosPickerItem)
        case viewBlurredMedia(GalleryItem)
        case openFilters

        case fetchGallery
        case addMedia(LoadedMedia)
        case deleteMedia(GalleryItem)

        case likeMedia(GalleryItem)
        case unlikeMedia(GalleryItem)
    }

    var group: Domain.Group {
        if let currentGroup = GroupStorage.currentGroup {
            return Domain.Group(
                    id: currentGroup.id,
                    name: currentGroup.name,
                    imageURL: currentGroup.imageURL
                )
        } else {
            return Domain.Group(
                    id: -1,
                    name: "Anonymous",
                    imageURL: ""
                )
        }
    }

    var mediaPickerPresented: Bool = false
    var mediaSelection: PhotosPickerItem?

    var mediaUploadingDialogShown: Bool = false
    var uploadingMedia: LoadedMedia?

    var filterSettingsShown = false
    var blurredMediaShown = false
    var blurredMediaSelection: GalleryItem?

    var showToast: (String) -> Void

    private(set) var galleryItems = [GalleryItem]()

    private let transformer: PhotosPickerItemTransformer

    var viewingBlurredMedia: GalleryItem? {
        guard let blurredMediaSelection, blurredMediaShown else {
            return nil
        }
        return blurredMediaSelection
    }

    let backend: NetworkService

    init() {
        transformer = .init()
        showToast = { _ in }

        galleryItems = []
        backend = NetworkService()
    }

    func dispatch(_ intent: Intent, onSuccess: @escaping () -> Void = {}) async {
        switch intent {
        case .viewGallery:
            if mediaSelection != nil { mediaSelection = nil }
            mediaPickerPresented = true
        case .showMediasDialog:
            mediaUploadingDialogShown = true
        case let .selectOneMedia(item):
            do {
                let media = try await self.transformer.transform(source: item)
                uploadingMedia = media
            } catch {
                showToast(UIComponentsStrings.MediaUpload.error)
            }
        case let .viewBlurredMedia(galleryItem):
            withAnimation {
                blurredMediaSelection = galleryItem
                blurredMediaShown = true
            }
        case .openFilters:
            filterSettingsShown = true
        case let .addMedia(loadedMedia):
            do {
                if let tokens = Tokens(), let groupId = GroupStorage.currentGroup?.id {
                    switch loadedMedia.content {
                    case let .image(image):
                        let response = try await backend.addMedia(
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
                        withAnimation {
                            onSuccess()
                            galleryItems = [
                                GalleryItem(
                                    isFavourite: false,
                                    tags: loadedMedia.tags?.map { $0.tag } ?? [],
                                    memory: response.toMediaItem()
                                )
                            ] + galleryItems
                        }
                    case .video:
                        print()
                    }
                }
            } catch {
                showToast(UIComponentsStrings.Toast.error)
            }
        case .fetchGallery:
            do {
                if let tokens = Tokens(), let groupId = GroupStorage.currentGroup?.id {
                    let response = try await backend.getMedias(tokens: tokens, groupId: groupId)
                    galleryItems = response.memories?.map {
                        return $0.toGalleryItem()
                    } ?? []
                }
            } catch {
                showToast(UIComponentsStrings.Toast.error)
            }
        case let .deleteMedia(galleryItem):
            do {
                if let tokens = Tokens(), let groupId = GroupStorage.currentGroup?.id {
                    let response = try await backend.deleteMedia(
                        tokens: tokens,
                        groupId: groupId,
                        memoryId: galleryItem.id
                    )
                    if response.success {
                        withAnimation {
                            onSuccess()
                            galleryItems.removeAll { $0.id == galleryItem.id }
                        }
                    }
                }
            } catch {
                showToast(UIComponentsStrings.Toast.error)
            }
        case let .likeMedia(galleryItem):
            do {
                if let tokens = Tokens(), let groupId = GroupStorage.currentGroup?.id {
                    _ = try await backend.likeMedia(
                        tokens: tokens,
                        groupId: groupId,
                        memoryId: galleryItem.id
                    )
                }
            } catch {
                showToast(UIComponentsStrings.Toast.error)
            }
        case let .unlikeMedia(galleryItem):
            do {
                if let tokens = Tokens(), let groupId = GroupStorage.currentGroup?.id {
                    _ = try await backend.unlikeMedia(
                        tokens: tokens,
                        groupId: groupId,
                        memoryId: galleryItem.id
                    )
                }
            } catch {
                showToast(UIComponentsStrings.Toast.error)
            }
        }
    }

    func set(showToast: @escaping (String) -> Void) {
        self.showToast = showToast
    }

    // временно
    // swiftlint:disable line_length
    private static func fetchTrack() -> Track? {
        let json = """
        {
          "id": 2026794888,
          "title": "миражи — кружок хора (>∆<)",
          "artwork_url": "https://i1.sndcdn.com/artworks-1WyHHVfSQvKviNzI-bP1zeA-large.jpg",
          "duration": 247063,
          "media": {
            "transcodings": [
              {
                "url": "https://api-v2.soundcloud.com/media/soundcloud:tracks:2026794888/cf1a0f7f-7d0e-4ce8-b601-656593f23ab3/stream/progressive",
                "preset": "mp3_1_0",
                "duration": 247066,
                "snipped": false,
                "format": {
                  "protocol": "progressive",
                  "mime_type": "audio/mpeg"
                },
                "quality": "sq",
                "is_legacy_transcoding": true
              }
            ]
          },
          "user": {
            "username": "skibidi rizz"
          }
        }
        """

        let data = Data(json.utf8)
        let track = try? JSONDecoder().decode(Track.self, from: data)
        return track
    }
    // swiftlint:enable line_length
}
