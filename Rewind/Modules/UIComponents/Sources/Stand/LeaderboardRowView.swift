import SwiftUI
import Domain

public struct LeaderboardRowView: View {
    private let rank: Int
    private let member: Member
    private let count: Int
    private let counterType: CounterType

    public init(
        rank: Int,
        member: Member,
        count: Int,
        counterType: CounterType
    ) {
        self.rank = rank
        self.member = member
        self.count = count
        self.counterType = counterType
    }

    public var body: some View {
        HStack {
            Text("\(rank)")
                .modifier(RoundFontModifier(size: 16, foregroundColor: Color.primary))
                .padding(.trailing, 8)

            SquareAsyncMedia(
                url: URL(string: member.imageURL),
                type: .image,
                cornerRadius: 12
            ).frame(48)

            Text(member.name)
                .modifier(RoundFontModifier(size: 16, foregroundColor: Color.primary))
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()

            Text("\(count) \(counterType)")
                .modifier(RoundFontModifier(size: 14, foregroundColor: Color.primary))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
    }
}
