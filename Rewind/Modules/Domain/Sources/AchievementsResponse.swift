import Foundation

public struct Achievement: Codable {
    public let icon: String
    public let isUnlocked: Bool
    public let name: String
    
    enum CodingKeys: String, CodingKey {
        case icon
        case isUnlocked = "is_unlocked"
        case name
    }
}

public struct AchievementsResponse: Codable {
    public let achievements: [Achievement]
}
