import SwiftUI

// Saving image
public func saveImageWithToast(image: UIImage?, toastAction: @escaping (String) -> Void) {
    guard let image else {
        toastAction(UIComponentsStrings.Toast.ImageSaving.failure)
        return
    }

    ImageSaver.shared.writeToPhotoAlbum(image: image) { result in
        switch result {
        case .success:
            toastAction(UIComponentsStrings.Toast.ImageSaving.success)
        case .failure:
            toastAction(UIComponentsStrings.Toast.ImageSaving.failure)
        }
    }
}
