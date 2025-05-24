import Foundation
import SwiftUI

final class ImageSaver: NSObject {
    public static var shared = ImageSaver()

    private var completion: ((Result<Void, Error>) -> Void)?

    func writeToPhotoAlbum(
        image: UIImage,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        self.completion = completion
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveCompleted), nil)
    }

    @objc
    private func saveCompleted(
        _ image: UIImage,
        didFinishSavingWithError error: Error?,
        contextInfo: UnsafeRawPointer
    ) {
        if let error = error {
            completion?(.failure(error))
        } else {
            completion?(.success(()))
        }
        completion = nil
    }
}
