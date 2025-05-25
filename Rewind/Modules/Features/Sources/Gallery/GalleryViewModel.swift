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
        case viewBlurredMedia(UIImage)
        case openFilters
    }

    var mediaPickerPresented: Bool = false
    var mediaSelection: PhotosPickerItem?

    var mediaUploadingDialogShown: Bool = false
    var uploadingMedia: LoadedMedia?

    var filterSettingsShown = false
    var blurredMediaShown = false
    var blurredMediaSelection: UIImage?

    var showToast: (String) -> Void

    private let transformer: PhotosPickerItemTransformer

    var viewingBlurredMedia: UIImage? {
        guard let blurredMediaSelection, blurredMediaShown else {
            return nil
        }
        return blurredMediaSelection
    }

    init() {
        transformer = .init()
        showToast = { _ in }
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
}
