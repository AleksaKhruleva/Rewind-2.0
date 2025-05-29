import SwiftUI
import Domain
import UIComponents
import Base

public struct StandView: View {
    private let counterType: CounterType
    private var members: [Member]
    private var podiumMembers: [PodiumMember]
    private let userRank: UserRank?

    private weak var router: AppRouter?

    public init(counterType: CounterType, members: [Member], router: AppRouter) {
        self.counterType = counterType
        self.router = router

        self.members = members.sorted {
            counterType == .rewinds
                ? $0.memoriesAddedCount > $1.memoriesAddedCount
                : $0.memoriesViewedCount > $1.memoriesViewedCount
        }

        podiumMembers = []
        for index in self.members.indices.prefix(3) {
            podiumMembers.append(self.members[index].toPodiumMember(rank: index + 1, counterType: counterType))
        }

        userRank = .fromMembers(self.members, counterType: counterType)
    }

    public var body: some View {
        ZStack {
            gradientBackground

            ScrollView(.vertical, showsIndicators: false) {
                header

                if let userRank {
                    VStack(spacing: 6) {
                        Text(counterType == .rewinds
                             ? UIComponentsStrings.Rewind.Stand.count(userRank.count)
                             : UIComponentsStrings.Rolls.Stand.count(userRank.count)
                        ).modifier(RoundFontModifier(size: 22, foregroundColor: Color.primary))

                        Text(UIComponentsStrings.Stand.rank(userRank.rank))
                            .modifier(RoundFontModifier(size: 16, foregroundColor: Color.primary))
                    }
                }

                HStack(alignment: .bottom) {
                    ForEach(podiumMembers) { podiumMember in
                        PodiumBadgeView(
                            rank: podiumMember.id,
                            member: podiumMember.member,
                            imageSize: podiumMember.imageSize,
                            count: podiumMember.count,
                            counterType: counterType,
                            badgeSize: podiumMember.badgeSize,
                            badgeColor: podiumMember.badgeColor
                        )
                    }
                }

                ForEach(members.indices.dropFirst(3), id: \.self) { index in
                    LeaderboardRowView(
                        rank: index + 1,
                        member: members[index],
                        count: counterType == .rolls
                            ? members[index].memoriesViewedCount
                            : members[index].memoriesAddedCount,
                        counterType: counterType
                    )
                }
            }
        }
    }

    // swiftlint:disable identifier_name
    private func lerpColor(_ c1: Color, _ c2: Color, fraction: Double) -> Color {
        let uiColor1 = UIColor(c1)
        let uiColor2 = UIColor(c2)

        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

        uiColor1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        uiColor2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        return Color(
            red: Double(r1 + (r2 - r1) * CGFloat(fraction)),
            green: Double(g1 + (g2 - g1) * CGFloat(fraction)),
            blue: Double(b1 + (b2 - b1) * CGFloat(fraction)),
            opacity: Double(a1 + (a2 - a1) * CGFloat(fraction))
        )
    }

    private var gradientBackground: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSince1970 * 0.5
            let sinValue = (sin(t) + 1) / 2

            let background = Color.background

            let accentColors = [
                Color(red: 0.6, green: 0.8, blue: 1.0),
                Color(red: 0.8, green: 0.9, blue: 0.7),
                Color(red: 1.0, green: 0.85, blue: 0.7),
                Color(red: 0.9, green: 0.7, blue: 0.9),
                Color(red: 0.7, green: 0.9, blue: 0.9)
            ]

            let count = accentColors.count
            let index = Int(t) % count
            let nextIndex = (index + 1) % count

            let fraction = t - floor(t)

            let accent = lerpColor(accentColors[index], accentColors[nextIndex], fraction: fraction)

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
    // swiftlint:enable identifier_name

    private var header: some View {
        RewindHeader(backgroundColor: .clear, rightView: {
            RewindButton(type: .rightChevron, tint: Color.primary) {
                router?.pop()
            }
        })
    }
}
