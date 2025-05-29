import Foundation

extension String {
    public func toISO8601String() -> String? {
        let inputFormatter = DateFormatter()
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
        inputFormatter.dateFormat = "dd.MM.yyyy HH:mm"

        guard let date = inputFormatter.date(from: self) else { return nil }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return isoFormatter.string(from: date)
    }

    public func toDate() -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter.date(from: self)
    }
}

extension Date {
    public func toString() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter.string(from: self)
    }
}

extension Optional where Wrapped == Date {
    public var daysSince: Int {
        guard let date = self else { return 0 }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.startOfDay(for: Date())
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }
}
