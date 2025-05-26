import Foundation

public enum DateParser {
    static let iso8601WithFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    public static func parseISODate(_ string: String) -> Date? {
        iso8601WithFractional.date(from: string)
    }
}
