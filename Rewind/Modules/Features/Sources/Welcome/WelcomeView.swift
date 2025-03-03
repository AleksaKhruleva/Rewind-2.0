import SwiftUI
import UIComponents

public struct WelcomeView: View {
    @State private var textWidth: CGFloat = 0
    
    public init() { }
    
    public var body: some View {
        ZStack {
            VStack {
                GradientTitle(text: "Rewind", fontSize: 80)
            }
            .modifier(VStackPositionModifier(topOffsetRatio: 0.39))
            
            VStack(spacing: 12) {
                GradientButton(title: "Sing in", width: textWidth) {
                    // TODO: do something later
                }
                
                Button {
                    // TODO: do something later
                } label: {
                    Text("Have an account?")
                        .modifier(RoundFontModifier(size: 20, foregroundColor: Color(hex: "FF6DB6")))
                        .modifier(MeasureWidthModifier(width: $textWidth))
                }
            }
            .modifier(VStackPositionModifier(topOffsetRatio: 0.91))
        }
    }
}

#Preview {
    WelcomeView()
}
