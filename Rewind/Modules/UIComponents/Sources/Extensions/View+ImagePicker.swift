import SwiftUI

extension View {
    @ViewBuilder
    public func customImagePicker(
        show: Binding<Bool>,
        cropType: CropType = .circle,
        croppedImage: Binding<UIImage?>,
        onSuccess: @escaping (UIImage) -> Void = { _ in },
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        RewindImagePicker(
            show: show,
            croppedImage: croppedImage,
            cropType: cropType,
            onSuccess: onSuccess,
            onDismiss: onDismiss
        ) {
            self
        }
    }
}
