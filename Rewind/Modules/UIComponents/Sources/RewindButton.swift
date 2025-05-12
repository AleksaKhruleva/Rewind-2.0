import SwiftUI

public struct RewindButton: View {
    public enum ButtonType: String {
        case leftChevron = "chevron.left"
        case rightChevron = "chevron.right"
        case trash = "trash"
        case xmark
        case checkmark
        case plus
        case gearshape = "gearshape.fill"
        case crop
        case selectVideo = "film.stack.fill"
        case photo = "photo.fill"
    }
    
    private let type: ButtonType
    private let tint: Color
    private let action: () -> Void
    
    public init(
        type: ButtonType,
        tint: Color = .textPrimary,
        action: @escaping () -> Void = {}
    ) {
        self.type = type
        self.tint = tint
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Image(systemName: type.rawValue)
                .font(.system(size: 20, weight: .black))
                .frame(width: 40, height: 40)
                .tint(tint)
        }
    }
}
