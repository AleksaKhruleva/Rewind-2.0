import SwiftUI

public struct RewindMediaButton: View {
    public enum ButtonType: String {
        case like = "heart"
        case save = "square.and.arrow.down.fill"
        case plus = "plus"
        case rewind = "arrowtriangle.right.fill"
        case settings = "gearshape.fill"
    }
    
    private let size: CGFloat
    private let fontSize: CGFloat
    private let type: ButtonType
    private let fillable: Bool
    private let filledColor: Color
    private let action: () -> Void
    
    @State private var filled: Bool = false
    
    public init(
        size: CGFloat = 40,
        fontSize: CGFloat = 22,
        type: ButtonType,
        fillable: Bool = false,
        filledColor: Color = .pinkPrimary,
        action: @escaping () -> Void = {}
    ) {
        self.size = size
        self.fontSize = fontSize
        self.type = type
        self.fillable = fillable
        self.filledColor = filledColor
        self.action = action
    }
    
    public var body: some View {
        Image(systemName: imageName)
            .font(.system(size: fontSize, weight: .bold))
            .frame(width: size, height: size)
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
            RewindMediaButton(type: .like, fillable: true) {
                print("like")
            }
            
            RewindMediaButton(type: .save) {
                print("save")
            }
        }
    }
}
