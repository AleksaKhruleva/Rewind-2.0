import SwiftUI
import PhotosUI
import Photos

public struct VideoPicker: UIViewControllerRepresentable {
    private var onPick: (PHAsset) -> Void
    
    public init(onPick: @escaping (PHAsset) -> Void) {
        self.onPick = onPick
    }
    
    public func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .videos
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    public func updateUIViewController(
        _ uiViewController: PHPickerViewController,
        context: Context
    ) {}
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    public class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onPick: (PHAsset) -> Void
        
        init(onPick: @escaping (PHAsset) -> Void) {
            self.onPick = onPick
        }
        
        public func picker(
            _ picker: PHPickerViewController,
            didFinishPicking results: [PHPickerResult]
        ) {
            picker.dismiss(animated: true)
            guard let identifier = results.first?.assetIdentifier else { return }
            
            let assetResults = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
            guard let asset = assetResults.firstObject else { return }
            
            onPick(asset)
        }
    }
}
