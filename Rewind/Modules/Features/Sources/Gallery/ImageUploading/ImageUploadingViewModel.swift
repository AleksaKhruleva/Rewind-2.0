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
    }
    
    var loadedMedia: LoadedMedia?
    var initialImage: UIImage?
    var selectedTrack: Track?
    var imagePickerPresented: Bool = false
    var imageEditorPresented: Bool = false
    var findTrackViewPresented: Bool = false
    
    var image: UIImage? {
        guard let loadedMedia, case let .image(image) = loadedMedia.content else {
            return nil
        }
        return image
    }
    
    var loadedMediaTagsBinding: Binding<[String]> {
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
    }
    
    func dispatch(_ intent: Intent) {
        switch intent {
        case .viewGallery:
            imagePickerPresented = true
        case .cropImage:
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
        case .findTrack:
            findTrackViewPresented = true
        case let .trackSelected(track):
            selectedTrack = track
        }
    }
}
