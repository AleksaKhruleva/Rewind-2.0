import SwiftUI

// удалить позже
import UIComponents

import Networking
import Base
import Domain

@MainActor @Observable
final class RewindViewModel {
    enum Intent {
        case fetchUser
        case toggleTrackPlaying
        case showNextMediaItem
    }

    var showToast: (String) -> Void
    var isTrackPlaying = false
    var rolls = 0
    private(set) var currentMediaItem: MediaItem

    var fetchedUser: User?
    var user: User {
        get {
            guard let fetchedUser else {
                //                router.navigateToWelcome() // TODO: return when routing is ready
                return User(name: "", email: "")
            }
            return fetchedUser
        }
        set {
            fetchedUser = newValue
        }
    }

    private let backend: NetworkServiceProtocol
    private let audioManager: AudioPlayerManager
    private var mediaItems = [MediaItem]()
    private var currentIndex = 0

    init() {
        showToast = { _ in }
        backend = NetworkService()
        audioManager = AudioPlayerManager.shared

        // временно
        let items = [
            MediaItem(
                type: .imageWithMusic,
                image: UIComponentsAsset.media21.image,
                track: Self.fetchTrack()
            ),
            MediaItem(
                type: .image,
                image: UIComponentsAsset.media16.image
            )
        ]

        mediaItems = items
        currentMediaItem = items[0]
    }

    func dispatch(_ intent: Intent) {
        switch intent {
        case .fetchUser:
            Task {
                do {
                    guard let tokens = Tokens() else {
                        //                        router.navigateToWelcome() // TODO: return when routing is ready
                        return
                    }
                    let response = try await backend.user(tokens: tokens)
                    user = response.toUser()
                } catch {
                    showToast("\(error.localizedDescription) 😨")
                }
            }
        case .toggleTrackPlaying:
            if !isTrackPlaying {
                guard let streamURL = currentMediaItem.track?.streamURL else {
                    return
                }
                audioManager.load(url: streamURL)
                audioManager.play(from: .zero, duration: 15.0) { [weak self] isPlaying in
                    self?.isTrackPlaying = isPlaying
                }
            } else {
                stopPlayer()
            }
        case .showNextMediaItem:
            stopPlayer()
            withAnimation {
                rolls += 1
                currentIndex = (currentIndex + 1) % mediaItems.count
                currentMediaItem = mediaItems[currentIndex]
            }
        }
    }

    func set(showToast: @escaping (String) -> Void) {
        self.showToast = showToast
    }

    private func stopPlayer() {
        isTrackPlaying = false
        audioManager.stop()
    }

    // временно
    private static func fetchTrack() -> Track? {
        let json = """
        {
          "id": 2026794888,
          "title": "миражи — кружок хора (>∆<)",
          "artwork_url": "https://i1.sndcdn.com/artworks-1WyHHVfSQvKviNzI-bP1zeA-large.jpg",
          "duration": 247063,
          "media": {
            "transcodings": [
              {
                "url": "https://api-v2.soundcloud.com/media/soundcloud:tracks:2026794888/cf1a0f7f-7d0e-4ce8-b601-656593f23ab3/stream/progressive",
                "preset": "mp3_1_0",
                "duration": 247066,
                "snipped": false,
                "format": {
                  "protocol": "progressive",
                  "mime_type": "audio/mpeg"
                },
                "quality": "sq",
                "is_legacy_transcoding": true
              }
            ]
          },
          "user": {
            "username": "skibidi rizz"
          }
        }
        """

        let data = Data(json.utf8)
        let track = try? JSONDecoder().decode(Track.self, from: data)
        return track
    }
}
