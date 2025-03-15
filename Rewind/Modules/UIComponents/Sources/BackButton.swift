import SwiftUI

public struct BackButton: View {
    public enum Direction {
        case left, right
    }
    
    private let direction: Direction
    private let action: () -> Void
    
    public init(direction: Direction, action: @escaping () -> Void) {
        self.direction = direction
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Image(systemName: direction == .left ? "chevron.left" : "chevron.right")
                .font(.system(size: 20, weight: .black))
                .frame(width: 40, height: 40)
                .tint(UIComponentsAsset.primaryColor.swiftUIColor)
        }
    }
}

public struct RewindButton: View {
    public enum ButtonType: String {
        case leftChevron = "chevron.left"
        case rightChevron = "chevron.right"
        case xmark
        case checkmark
        case plus
        case empty
    }
    
    private let type: ButtonType
    private let action: () -> Void
    
    public init(type: ButtonType, action: @escaping () -> Void) {
        self.type = type
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            Image(systemName: type.rawValue)
                .font(.system(size: 20, weight: .black))
                .frame(width: 40, height: 40)
                .tint(UIComponentsAsset.primaryColor.swiftUIColor)
                .opacity(type == .empty ? 0 : 1)
        }
    }
}

#Preview {
    VStack {
        BackButton(direction: .left) {
            print("Tapped left")
        }
        BackButton(direction: .right) {
            print("Tapped right")
        }
        RewindButton(type: .plus) {
            print("plus")
        }
        RewindButton(type: .xmark) {
            print("xmark")
        }
    }
}
