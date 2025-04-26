import SwiftUI

public struct RewindRollsStat: View {
    @Binding var rolls: Int
    
    public init(rolls: Binding<Int>) {
        self._rolls = rolls
    }
    
    public var body: some View {
        HStack {
            Text("\(rolls)")
                .font(UIComponentsFontFamily.Rubik.black.swiftUIFont(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: "6DD668"), Color(hex: "00CCCC")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(.vertical, -10)
            
            Text("Rewind\nrolls today!")
                .modifier(RoundFontModifier(size: 15))
        }
    }
}
