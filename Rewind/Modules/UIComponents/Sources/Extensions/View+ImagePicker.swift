import SwiftUI

extension View {
    @ViewBuilder
    public func customImagePicker(
        show: Binding<Bool>,
        croppedImage: Binding<UIImage?>,
        onSuccess: @escaping() -> Void = {}
    ) -> some View {
        RewindImagePicker(show: show, croppedImage: croppedImage, onSuccess: onSuccess) {
            self
        }
    }
}
