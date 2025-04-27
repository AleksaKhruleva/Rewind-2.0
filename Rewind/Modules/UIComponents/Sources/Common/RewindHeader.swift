import SwiftUI

public struct RewindHeader<LeftContent: View, CenterContent: View, RightContent: View>: View {
    private let backgroundColor: Color
    private let leftView: LeftContent
    private let centerView: CenterContent
    private let rightView: RightContent
    
    @Environment(\.dismiss)
    private var dismiss

    public init(
        backgroundColor: Color = .white,
        @ViewBuilder leftView: () -> LeftContent,
        @ViewBuilder centerView: () -> CenterContent = { EmptyView() },
        @ViewBuilder rightView: () -> RightContent = { EmptyView() }
    ) {
        self.backgroundColor = backgroundColor
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
        .background(backgroundColor)
    }
}

