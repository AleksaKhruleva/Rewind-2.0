import SwiftUI

private let selectorWidth: CGFloat = 130

public struct WaveformView: View {
    @Binding var selectorDuration: CGFloat
    private let trackDuration: CGFloat
    private let sidePaddingWidth: CGFloat

    public init(
        selectorDuration: Binding<CGFloat>,
        trackDuration: CGFloat,
        sidePaddingWidth: CGFloat
    ) {
        self._selectorDuration = selectorDuration
        self.trackDuration = trackDuration
        self.sidePaddingWidth = sidePaddingWidth
    }

    public var body: some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(Color.clear)
                .frame(width: sidePaddingWidth)

            ForEach(0 ..< barCount, id: \.self) { count in
                let coef: CGFloat = count % 2 == 0 ? 0.5 : 1
                SoundBar(coefficient: coef, color: .pinkPrimaryLight)
            }

            Rectangle()
                .fill(Color.clear)
                .frame(width: sidePaddingWidth)
        }
    }

    private var totalWidth: CGFloat {
        selectorWidth * (trackDuration / selectorDuration)
    }

    private var barCount: Int {
        Int(totalWidth / 11)
    }
}

#Preview {
    ScrollView(.horizontal, showsIndicators: false) {
        WaveformView(
            selectorDuration: .constant(15),
            trackDuration: 30,
            sidePaddingWidth: 6
        )
    }
}
