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
        case viewBlurredMedia(MediaItem)
        case openFilters
        
        case addMedia(LoadedMedia)
    }

    var mediaPickerPresented: Bool = false
    var mediaSelection: PhotosPickerItem?

    var mediaUploadingDialogShown: Bool = false
    var uploadingMedia: LoadedMedia?

    var filterSettingsShown = false
    var blurredMediaShown = false
    var blurredMediaSelection: MediaItem?

    var showToast: (String) -> Void

    private(set) var mediaItems = [MediaItem]()

    private let transformer: PhotosPickerItemTransformer

    var viewingBlurredMedia: MediaItem? {
        guard let blurredMediaSelection, blurredMediaShown else {
            return nil
        }
        return blurredMediaSelection
    }
    
    let backend: NetworkServiceProtocol

    init() {
        transformer = .init()
        showToast = { _ in }

        mediaItems = MediaItem.stubs(track: Self.fetchTrack())
        backend = NetworkService()
    }

    func dispatch(_ intent: Intent) async {
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
        case let .viewBlurredMedia(media):
            withAnimation {
                blurredMediaSelection = media
                blurredMediaShown = true
            }
        case .openFilters:
            filterSettingsShown = true
        case let .addMedia(loadedMedia):
            do {
                if let tokens = Tokens(), let groupId = GroupStorage.currentGroup?.id {
                    switch loadedMedia.content {
                    case let .image(image):
                        let _ = try await backend.addMedia(
                            tokens: tokens,
                            groupId: groupId,
                            mediaType: "image",
                            mediaFile: image,
                        )
                    case .video:
                        print("good")
                    }
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
