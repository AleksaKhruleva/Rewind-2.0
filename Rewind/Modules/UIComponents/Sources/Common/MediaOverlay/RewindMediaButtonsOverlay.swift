import SwiftUI

public struct RewindMediaButtonsOverlay: View {
    private let isLiked: Bool
    private let likeAction: (Bool) -> Void
    private let saveAction: () -> Void

    public init(
        isLiked: Bool,
        likeAction: @escaping (Bool) -> Void,
        saveAction: @escaping () -> Void
    ) {
        self.isLiked = isLiked
        self.likeAction = likeAction
        self.saveAction = saveAction
    }

    public var body: some View {
        VStack {
            Spacer()
            HStack {
                RewindMediaButton(type: .save) { saveAction() }
                Spacer()
                RewindMediaButton(
                    type: .like,
                    fillable: true,
                    filled: isLiked,
                    fillableAction: likeAction
                )
            }
        }
        .padding(8 * 1.5)
    }
}
