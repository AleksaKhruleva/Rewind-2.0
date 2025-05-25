import SwiftUI

public struct BlurredAvatarView: View {
    @State private var showPicker: Bool = false
    @Binding var image: UIImage?
    @Binding var isPresented: Bool

    @Environment(\.showToast)
    private var showToast

    public init(isPresented: Binding<Bool>, image: Binding<UIImage?>) {
        self._image = image
        self._isPresented = isPresented
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
          .customImagePicker(show: $showPicker, croppedImage: $image) {
              showToast(UIComponentsStrings.Account.Edit.Image.Set.success)
          }
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

#Preview {
    BlurredAvatarView(
        isPresented: Binding.constant(true),
        image: .constant(UIComponentsAsset.avatar.image)
    )
}
