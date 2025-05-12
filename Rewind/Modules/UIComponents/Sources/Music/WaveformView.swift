import SwiftUI

let defaultCoefficient: [CGFloat] = (0..<100).map { $0 % 2 == 0 ? 0.5 : 1 }

public struct WaveformView: View {
    private let sidePaddingWidth: CGFloat
    
    public init(sidePaddingWidth: CGFloat) {
        self.sidePaddingWidth = sidePaddingWidth
    }
    
    public var body: some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(Color.clear)
                .frame(width: sidePaddingWidth)
            
            ForEach(defaultCoefficient, id: \.self) { coef in
                SoundBar(coefficient: coef, color: .pinkPrimaryLight)
            }
            
            Rectangle()
                .fill(Color.clear)
                .frame(width: sidePaddingWidth)
        }
    }
}

#Preview {
    WaveformView(sidePaddingWidth: 6)
}
