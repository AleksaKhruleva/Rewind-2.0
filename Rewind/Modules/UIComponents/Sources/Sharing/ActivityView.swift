import SwiftUI

public struct ActivityView: UIViewControllerRepresentable {
    private let activityItems: [Any]
    @Binding var isPresented: Bool
    
    public init(activityItems: [Any], isPresented: Binding<Bool>) {
        self.activityItems = activityItems
        self._isPresented = isPresented
    }
    
    public func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        controller.completionWithItemsHandler = { _, _, _, _ in
            isPresented = false
        }
        
        return controller
    }
    
    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
