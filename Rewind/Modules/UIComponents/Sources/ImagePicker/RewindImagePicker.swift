import SwiftUI
import PhotosUI

struct RewindImagePicker<Content: View>: View {
    var content: Content
    @Binding var show: Bool
    @Binding var cropedImage: UIImage?
    
    @State private var pickerItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isImageEditorPresented: Bool = false
    
    init(
        show: Binding<Bool>,
        croppedImage: Binding<UIImage?>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._show = show
        self._cropedImage = croppedImage
        self.content = content()
    }
    
    var body: some View {
        content
            .photosPicker(isPresented: $show, selection: $pickerItem)
            .onChange(of: pickerItem) { _, newValue in
                guard let newValue else { return }
                Task {
                    if let imageData = try? await newValue.loadTransferable(type: Data.self),
                       let image = UIImage(data: imageData) {
                        await MainActor.run {
                            selectedImage = image
                            isImageEditorPresented.toggle()
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $isImageEditorPresented) {
                selectedImage = nil
            } content: {
                RewindImageEditor(image: $selectedImage) { croppedImage, status in
                    guard let croppedImage else { return }
                    self.cropedImage = croppedImage
                }
            }
    }
}

#Preview {
    RewindImageEditor(image: Binding.constant(UIComponentsAsset.avatar.image)) { _, _ in
        
    }
}
