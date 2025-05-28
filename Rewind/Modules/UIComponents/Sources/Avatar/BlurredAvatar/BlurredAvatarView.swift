import SwiftUI

public struct BlurredAvatarView: View {
    @State private var showPicker: Bool = false
    @Binding var image: UIImage?
    @Binding var isPresented: Bool
    var onSuccess: (UIImage) -> Void

    @Environment(\.showToast)
    private var showToast

    public init(
        isPresented: Binding<Bool>,
        image: Binding<UIImage?>,
        onSuccess: @escaping (UIImage) -> Void = { _ in }
    ) {
        self._image = image
        self._isPresented = isPresented
        self.onSuccess = onSuccess
    }

    public var body: some View {
      Color.black.opacity(0.05)
          .background(BlurView())
          .overlay(
            content
          )
          .ignoresSafeArea()
          .onTapGesture {
              withAnimation {
                  isPresented = false
              }
          }
          .customImagePicker(show: $showPicker, croppedImage: $image, onSuccess: onSuccess)
    }

    public var content: some View {
        VStack(spacing: 16) {
            Image(uiImage: image ?? UIComponentsAsset.avatar.image)
                .resizable()
                .frame(width: 320, height: 320)
                .clipShape(Circle())

            BlurredAvatarTable(
                showPicker: $showPicker,
                saveImage: {
                    saveImageWithToast(image: image) { message in
                        showToast(message)
                    }
                }
            )
        }
    }
}
