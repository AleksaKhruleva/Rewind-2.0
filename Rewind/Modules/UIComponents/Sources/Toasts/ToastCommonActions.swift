import SwiftUI

enum ToastActionMessages: String {
    case imageSavingSuccess = "Your image was saved successfully 🤗"
    case imageSavingFailure = "Failed to save your image 😢"
}

// Saving image
func saveImageWithToast(image: UIImage?, toastAction: @escaping (String) -> Void) {
    guard let image else {
        toastAction(ToastActionMessages.imageSavingFailure.rawValue)
        return
    }
    
    ImageSaver.shared.writeToPhotoAlbum(image: image) { result in
        switch result {
        case .success:
            toastAction(ToastActionMessages.imageSavingSuccess.rawValue)
        case .failure:
            toastAction(ToastActionMessages.imageSavingFailure.rawValue)
        }
    }
}
