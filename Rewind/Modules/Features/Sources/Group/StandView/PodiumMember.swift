import SwiftUI
import Domain
import UIComponents
import Foundation

struct PodiumMember: Identifiable {
    let id: Int
    let member: Member
    let imageSize: CGFloat
    let badgeSize: CGFloat
    let badgeColor: Color
    let count: Int

    init(
        rank: Int,
        member: Member,
        imageSize: CGFloat,
        badgeSize: CGFloat,
        badgeColor: Color,
        count: Int
    ) {
        self.id = rank
        self.member = member
        self.imageSize = imageSize
        self.badgeSize = badgeSize
        self.badgeColor = badgeColor
        self.count = count
    }
}

extension Member {
    func toPodiumMember(rank: Int, counterType: CounterType) -> PodiumMember {
        PodiumMember(
            rank: rank,
            member: self,
            imageSize: rank.imageSize,
            badgeSize: rank.badgeSize,
            badgeColor: rank.badgeColor,
            count: counterType == .rolls
                ? memoriesViewedCount
                : memoriesAddedCount
        )
    }
}

extension Int {
    fileprivate var imageSize: CGFloat {
        switch self {
        case 1: 110
        case 2: 85
        case 3: 75
        default: 75
        }
    }

    fileprivate var badgeSize: CGFloat {
        switch self {
        case 1: 36
        case 2: 32
        case 3: 26
        default: 26
        }
    }

    fileprivate var badgeColor: Color {
        switch self {
        case 1: Color.yellow
        case 2: Color.gray
        case 3: Color(uiColor: .brown)
        default: Color(uiColor: .brown)
        }
    }
}
