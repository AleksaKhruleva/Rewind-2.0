import SwiftUI

public struct BlurredAvatarView: View {
    @State private var image: UIImage?
    @State private var showPicker: Bool = false
    @Binding var isPresented: Bool

    public init(image: UIImage, isPresented: Binding<Bool>) {
        self.image = image
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
                  isPresented.toggle()
              }
          }
          .customImagePicker(show: $showPicker, croppedImage: $image)
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
                    // TODO: smth
                }
            )
        }
    }
}

#Preview {
    BlurredAvatarView(
        image: UIComponentsAsset.avatar.image,
        isPresented: Binding.constant(true)
    )
}
