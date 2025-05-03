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
                RewindMediaButton(type: .save) { saveAction() }
                Spacer()
                RewindMediaButton(type: .like, fillable: true) { likeAction() }
            }
        }
        .padding(8 * 1.5)
    }
}
