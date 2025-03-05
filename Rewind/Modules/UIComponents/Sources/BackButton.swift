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

#Preview {
    VStack {
        BackButton(direction: .left) {
            print("Tapped left")
        }
        BackButton(direction: .right) {
            print("Tapped right")
        }
    }
}
