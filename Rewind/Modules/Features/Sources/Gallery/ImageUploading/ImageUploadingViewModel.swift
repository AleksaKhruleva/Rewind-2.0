import SwiftUI
import Domain

@MainActor @Observable
final class ImageUploadingViewModel {
    enum Intent {
        enum ChangeImageType {
            case hard
            case soft
        }

        case viewGallery
        case cropImage
        case changeImage(UIImage?, ChangeImageType = .soft)
        case findTrack
        case trackSelected(Track)
        case resumePlayback
    }

    var loadedMedia: LoadedMedia?
    var initialImage: UIImage?
    var imagePickerPresented: Bool = false
    var imageEditorPresented: Bool = false
    var findTrackViewPresented: Bool = false
    var isSelectedTrackPlaying: Bool = true

    var selectedTrack: Track?
    var trackScrollOffset: CGFloat
    var selectedStartTime: Double = 0
    var selectedDuration: CGFloat = 15

    var image: UIImage? {
        guard let loadedMedia, case let .image(image) = loadedMedia.content else {
            return nil
        }
        return image
    }

    var loadedMediaTagsBinding: Binding<[MediaTag]> {
        Binding {
            return self.loadedMedia?.tags ?? []
        } set: { newTags in
            if self.loadedMedia != nil {
                self.loadedMedia?.tags = newTags
            }
        }
    }

    var imageBinding: Binding<UIImage?> {
        Binding {
            return self.image
        } set: { newImage in
            if let newImage {
                self.loadedMedia = .init(content: .image(newImage))
            }
        }
    }

    var ready: Bool {
        image != nil
    }

    init(loadedMedia: LoadedMedia?) {
        self.loadedMedia = loadedMedia
        if case let .image(image) = loadedMedia?.content {
            initialImage = image
        }
        selectedTrack = loadedMedia?.trackForMultipleUploading
        trackScrollOffset = loadedMedia?.trackForMultipleUploading?.scrollOffset ?? 0
        selectedStartTime = loadedMedia?.trackForMultipleUploading?.trackInfo?.startTime ?? 0
        selectedDuration = loadedMedia?.trackForMultipleUploading?.trackInfo?.duration ?? 15
    }

    func dispatch(_ intent: Intent) {
        switch intent {
        case .viewGallery:
            isSelectedTrackPlaying = false
            imagePickerPresented = true
        case .cropImage:
            isSelectedTrackPlaying = false
            imageEditorPresented = true
        case let .changeImage(image, type):
            if let image {
                if type == .hard { initialImage = image }
                guard loadedMedia != nil else {
                    loadedMedia = .init(content: .image(image))
                    return
                }
                loadedMedia?.content = .image(image)
            }
            isSelectedTrackPlaying = true
        case .findTrack:
            isSelectedTrackPlaying = false
            findTrackViewPresented = true
        case let .trackSelected(track):
            selectedTrack = track
        case .resumePlayback:
            isSelectedTrackPlaying = true
        }
    }
}
