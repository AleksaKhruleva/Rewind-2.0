import SwiftUI
import PhotosUI
import Base
import Domain
import UIComponents

@MainActor @Observable
final class GalleryViewModel {
    enum Intent {
        case viewGallery
        case showMediasDialog
        case selectOneMedia(PhotosPickerItem)
        case viewBlurredMedia(MediaItem)
        case openFilters
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
    
    init() {
        transformer = .init()
        showToast = { _ in }
        
        // временно
        let items = [
            MediaItem(
                type: .imageWithMusic,
                image: UIComponentsAsset.media21.image,
                track: Self.fetchTrack()
            ),
            MediaItem(
                type: .image,
                image: UIComponentsAsset.media16.image
            )
        ]
        
        mediaItems = items
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
        }
    }
    
    func set(showToast: @escaping (String) -> Void) {
        self.showToast = showToast
    }
    
    // временно
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
        var track = try? JSONDecoder().decode(Track.self, from: data)
        track?.streamURL = URL(
            string: "https://cf-media.sndcdn.com/wHq5ExUUltpj.128.mp3?Policy=eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiKjovL2NmLW1lZGlhLnNuZGNkbi5jb20vd0hxNUV4VVVsdHBqLjEyOC5tcDMqIiwiQ29uZGl0aW9uIjp7IkRhdGVMZXNzVGhhbiI6eyJBV1M6RXBvY2hUaW1lIjoxNzQ4MDg5MjMzfX19XX0_&Signature=Ot8fvGNEmq8ZpTgxBYq5xsFGxajYpv9dcy9O07JbGgR228szn6G1t0hJ2mUNF0qKnIhKOgcAR0R93Xu8xk7FXGIg4xQiXzKypgKYUDIBMN7bNyBFCVXNBYBDwEldoDSGCFzj9oxCp~JtQ0JNkFTWOpMRGP6PnVSw-qZpbbImYSI4BHFJQi7e1vgU9zhwhjtWTninbPW7mEfGCZnJQwZD7jEFqycxDR4mLvqFPUJiO9Lvrw4vIsLkSxbCMF~AohobcgQz6IEESAHL8gHSEllpjc4yF5bM0Y5hpvltJaJiJQAUPAsVypnjreyt6yg36VUOINx98OIRVuAQZ1QomPdiNQ__&Key-Pair-Id=APKAI6TU7MMXM5DG6EPQ"
        )
        return track
    }
}
