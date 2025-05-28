import SwiftUI
import PhotosUI
import Base

struct RewindImagePicker<Content: View>: View {
    var content: Content
    @Binding var show: Bool
    @Binding var cropedImage: UIImage?
    var cropType: CropType
    var onSuccess: (UIImage) -> Void
    var onDismiss: (() -> Void)?

    @State private var pickerItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isImageEditorPresented: Bool = false

    init(
        show: Binding<Bool>,
        croppedImage: Binding<UIImage?>,
        cropType: CropType,
        onSuccess: @escaping (UIImage) -> Void,
        onDismiss: (() -> Void)?,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._show = show
        self._cropedImage = croppedImage
        self.cropType = cropType
        self.onSuccess = onSuccess
        self.onDismiss = onDismiss
        self.content = content()
    }

    var body: some View {
        content
            .photosPicker(isPresented: $show, selection: $pickerItem, matching: .images)
            .onChange(of: pickerItem) { _, newValue in
                guard let newValue else { return }
                Task {
                    print(await MetaDataExtractor.shared.extractCoordinates(from: newValue) ?? "")
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
                pickerItem = nil
                selectedImage = nil
            } content: {
                RewindImageEditor(image: selectedImage, cropType: cropType) { croppedImage, status in
                    guard let croppedImage else { return }
                    self.cropedImage = croppedImage
                    if status { onSuccess(croppedImage) }
                }
            }
            .onChange(of: show) { _, newValue in
                if newValue == false && pickerItem == nil {
                    onDismiss?()
                }
            }
    }
}

#Preview {
    RewindImageEditor(image: UIComponentsAsset.avatar.image, cropType: .circle) { _, _ in

    }
}
