import SwiftUI

public struct RewindHeader<LeftContent: View, CenterContent: View, RightContent: View>: View {
    let leftView: LeftContent
    let centerView: CenterContent
    let rightView: RightContent

    public init(
        @ViewBuilder leftView: () -> LeftContent,
        @ViewBuilder centerView: () -> CenterContent,
        @ViewBuilder rightView: () -> RightContent
    ) {
        self.leftView = leftView()
        self.centerView = centerView()
        self.rightView = rightView()
    }

    public var body: some View {
        HStack {
            leftView
            Spacer()
            centerView
            Spacer()
            rightView
        }
        .padding([.bottom, .horizontal])
        .background(Color.white)
    }
}

