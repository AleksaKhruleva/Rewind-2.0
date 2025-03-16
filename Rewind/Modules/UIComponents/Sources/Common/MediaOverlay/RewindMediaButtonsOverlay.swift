import SwiftUI

public struct RewindMediaButtonsOverlay: View {
    private let likeAction: () -> Void
    private let saveAction: () -> Void
    
    public init(
        likeAction: @escaping () -> Void,
        saveAction: @escaping () -> Void
    ) {
        self.likeAction = likeAction
        self.saveAction = saveAction
    }
    
    public var body: some View {
        VStack {
            Spacer()
            
            HStack {
                RewindMediaButton(type: .like, fillable: true) {
                    likeAction()
                }
                
                Spacer()
                
                RewindMediaButton(type: .save) {
                    saveAction()
                }
            }
        }
        .padding(8 * 1.5)
    }
}
