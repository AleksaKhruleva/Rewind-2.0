import SwiftUI

// временно
let podiumMembers = [
    (index: 1, imageSize: 85.0, rank: 2, badgeSize: 32.0, badgeColor: Color.gray, count: 407),
    (index: 0, imageSize: 110.0, rank: 1, badgeSize: 36.0, badgeColor: Color.yellow, count: 1077),
    (index: 2, imageSize: 75.0, rank: 3, badgeSize: 26.0, badgeColor: Color(uiColor: .brown), count: 207)
]

public struct StandView: View {
    private let title: String
    private let counterType: CounterType

    public init(title: String, counterType: CounterType) {
        self.title = title
        self.counterType = counterType
    }

    public var body: some View {
        ZStack {
            gradientBackground

            ScrollView(.vertical, showsIndicators: false) {
                header

                VStack(spacing: 6) {
                    Text(title)
                        .modifier(RoundFontModifier(size: 22, foregroundColor: .white))

                    Text(UIComponentsStrings.Stand.rank(3))
                        .modifier(RoundFontModifier(size: 16, foregroundColor: .white))
                }

                HStack(alignment: .bottom) {
                    ForEach(podiumMembers, id: \.index) { podiumMember in
                        PodiumBadgeView(
                            rank: podiumMember.rank,
                            member: membersForTest[podiumMember.index],
                            imageSize: podiumMember.imageSize,
                            count: podiumMember.count,
                            counterType: counterType,
                            badgeSize: podiumMember.badgeSize,
                            badgeColor: podiumMember.badgeColor
                        )
                    }
                }

                ForEach(membersForTest.indices.dropFirst(3), id: \.self) { index in
                    LeaderboardRowView(
                        rank: index + 1,
                        member: membersForTest[index],
                        count: [123, 70, 7][index - 3],
                        counterType: counterType
                    )
                }
            }
        }
    }

    private var gradientBackground: some View {
        TimelineView(.animation) { timeline in
            let sinValue = (sin(timeline.date.timeIntervalSince1970) + 1) / 2

            let background = Color(hex: "000000")
            let accent = Color(hex: "0061ff")

            MeshGradient(width: 3, height: 3, points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], [Float(sinValue), 0.5], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1]
            ], colors: [
                background, background, background,
                background, accent, background,
                background, background, background
            ])
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        RewindHeader(backgroundColor: .clear, rightView: {
            RewindButton(type: .rightChevron, tint: .white) {
                // TODO: dismiss
            }
        })
    }
}

#Preview {
    StandView(title: "You rolled 70 Rewinds", counterType: .rolls)
    //    StandView(title: "You added 70 Rewinds", counterType: .rewinds)
}
