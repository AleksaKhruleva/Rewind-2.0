import Foundation
import Domain
import Base
import UIComponents

struct UserRank {
    let count: Int
    let rank: Int

    static func fromMembers(_ members: [Member], counterType: CounterType) -> Self? {
        if let token = Tokens()?.accessToken,
           let id = JWTDecoder().getUserId(from: token),
           let memberIndex = members.firstIndex(where: { $0.id == id }) {
            return Self(
                count: counterType == .rolls
                    ? members[memberIndex].memoriesViewedCount
                    : members[memberIndex].memoriesAddedCount,
                rank: memberIndex + 1
            )
        }
        return nil
    }
}
