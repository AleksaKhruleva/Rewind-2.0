import SwiftUI

private let selectorWidth: CGFloat = 130

public struct WaveformView: View {
    private let trackDuration: Double
    private let selectorDuration: Double
    private let sidePaddingWidth: CGFloat
    
    public init(
        trackDuration: Double,
        selectorDuration: Double,
        sidePaddingWidth: CGFloat
    ) {
        self.trackDuration = trackDuration
        self.selectorDuration = selectorDuration
        self.sidePaddingWidth = sidePaddingWidth
    }
    
    public var body: some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(Color.clear)
                .frame(width: sidePaddingWidth)
            
            ForEach(0 ..< barCount, id: \.self) { i in
                let coef: CGFloat = i % 2 == 0 ? 0.5 : 1
                SoundBar(coefficient: coef, color: .pinkPrimaryLight)
            }
            
            Rectangle()
                .fill(Color.clear)
                .frame(width: sidePaddingWidth)
        }
    }
    
    private var totalWidth: CGFloat {
        selectorWidth * CGFloat(trackDuration / selectorDuration)
    }
    
    private var barCount: Int {
        Int(totalWidth / 11)
    }
}

#Preview {
    ScrollView(.horizontal, showsIndicators: false) {
        WaveformView(
            trackDuration: 30,
            selectorDuration: 15,
            sidePaddingWidth: 6
        )
    }
}
