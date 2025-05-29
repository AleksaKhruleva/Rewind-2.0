import SwiftUI
import Domain

public enum CounterType {
    case rolls
    case rewinds
}

public struct PodiumBadgeView: View {
    private let rank: Int
    private let member: Member
    private let imageSize: CGFloat
    private let count: Int
    private let counterType: CounterType
    private let badgeSize: CGFloat
    private let badgeColor: Color

    public init(
        rank: Int,
        member: Member,
        imageSize: CGFloat,
        count: Int,
        counterType: CounterType,
        badgeSize: CGFloat,
        badgeColor: Color
    ) {
        self.rank = rank
        self.member = member
        self.imageSize = imageSize
        self.count = count
        self.counterType = counterType
        self.badgeSize = badgeSize
        self.badgeColor = badgeColor
    }

    public var body: some View {
        VStack(spacing: 5) {
            ZStack(alignment: .topTrailing) {
                SquareAsyncMedia(url: URL(string: member.imageURL), type: .image, cornerRadius: cornerRadius)
                    .frame(width: imageSize, height: imageSize)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white, lineWidth: 3)
                    )

                Text("\(rank)")
                    .modifier(RoundFontModifier(size: badgeSize * 0.5, foregroundColor: .white))
                    .frame(width: badgeSize, height: badgeSize)
                    .background(Circle().fill(badgeColor))
                    .overlay(
                        Circle().stroke(Color.white, lineWidth: 3)
                    )
                    .offset(x: 7, y: -7)
            }

            Text(member.name)
                .modifier(RoundFontModifier(size: 16, foregroundColor: Color.primary))
                .padding(.top, 4)

            Text("\(count) \(counterType)")
                .modifier(RoundFontModifier(size: 12, foregroundColor: Color.secondary))
        }
        .padding()
    }

    private var cornerRadius: CGFloat {
        imageSize * 0.25
    }
}
