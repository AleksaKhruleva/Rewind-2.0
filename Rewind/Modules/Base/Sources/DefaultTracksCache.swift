import Domain
import Foundation

public final class DefaultTracksCache {
    public static let shared = DefaultTracksCache()

    public private(set) var tracks: [Track] = []
    public private(set) var nextHref: String?

    private var lastStoreDate: Date?
    private let expirationInterval: TimeInterval = 10 * 60

    private var expirationTimer: DispatchWorkItem?

    private init() {}

    public func store(tracks: [Track], nextHref: String?) {
        self.tracks = tracks
        self.nextHref = nextHref
        self.lastStoreDate = Date()
        scheduleExpiration()
    }

    public func retrieve() -> ([Track], String?)? {
        return (tracks, nextHref)
    }

    private func clear() {
        tracks = []
        nextHref = nil
        lastStoreDate = nil
        expirationTimer?.cancel()
        expirationTimer = nil
    }

    private func scheduleExpiration() {
        expirationTimer?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if let lastStoreDate = self.lastStoreDate,
               Date().timeIntervalSince(lastStoreDate) >= self.expirationInterval {
                self.clear()
            }
        }

        expirationTimer = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + expirationInterval, execute: workItem)
    }
}
