import SwiftUI

extension View {
    @ViewBuilder
    public func customImagePicker(
        show: Binding<Bool>,
        cropType: CropType = .circle,
        croppedImage: Binding<UIImage?>,
        onSuccess: @escaping () -> Void = {}
    ) -> some View {
        RewindImagePicker(show: show, croppedImage: croppedImage, cropType: cropType, onSuccess: onSuccess) {
            self
        }
    }
}
