import SwiftUI

extension View {
    @ViewBuilder
    func customImagePicker(show: Binding<Bool>, croppedImage: Binding<UIImage?>) -> some View {
        RewindImagePicker(show: show, croppedImage: croppedImage) {
            self
        }
    }
}
