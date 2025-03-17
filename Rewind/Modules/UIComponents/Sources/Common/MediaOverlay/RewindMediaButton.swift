import SwiftUI

public struct RewindMediaButton: View {
    public enum ButtonType: String {
        case like = "heart"
        case save = "square.and.arrow.down.fill"
    }
    
    private let type: ButtonType
    private let fillable: Bool
    private let filledColor: Color
    private let action: () -> Void
    
    @State private var filled: Bool = false
    
    public init(
        type: ButtonType,
        fillable: Bool = false,
        filledColor: Color = UIComponentsAsset.pinkColor.swiftUIColor,
        action: @escaping () -> Void = {}
    ) {
        self.type = type
        self.fillable = fillable
        self.filledColor = filledColor
        self.action = action
    }
    
    public var body: some View {
        Image(systemName: imageName)
            .font(.system(size: 22, weight: .bold))
            .frame(width: 40, height: 40)
            .background(Color.white.opacity(0.5))
            .foregroundColor(foregroundColor)
            .clipShape(Circle())
            .simultaneousGesture(
                TapGesture().onEnded {
                    action()
                    toggle()
                }
            )
    }
}

extension RewindMediaButton {
    private var imageName: String {
        if fillable {
            return type.rawValue + (filled ? ".fill" : "")
        }
        
        return type.rawValue
    }
    
    private var foregroundColor: Color {
        if fillable {
            return filled ? filledColor : .white
        }
        
        return .white
    }
    
    private func toggle() {
        withAnimation(.easeInOut(duration: 0.1)) {
            filled.toggle()
        }
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.9).ignoresSafeArea()
        
        HStack {
            RewindMediaButton(type: .like, fillable: true) { print("like") }
            RewindMediaButton(type: .save) { print("save") }
        }
    }
}
