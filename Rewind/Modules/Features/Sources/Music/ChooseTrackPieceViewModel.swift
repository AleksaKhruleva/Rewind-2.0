import SwiftUI
import Networking
import Base
import Domain

@MainActor @Observable
final class ChooseTrackPieceViewModel {
    enum Intent {
        case playTrack(startTime: Double, duration: Double?, loop: Bool = false)
        case stopPlaying
        case destroyPlayer
    }

    var toastMessage: String?

    private(set) var selectedTrack: Track
    private(set) var isTrackPlaying: Bool = false

    private let backend: SoundCloudServiceProtocol
    private let playerManager: AudioPlayerManager

    init(selectedTrack: Track) {
        self.selectedTrack = selectedTrack

        backend = SoundCloudNetworkService()
        playerManager = AudioPlayerManager.shared
    }

    func dispatch(_ intent: Intent) {
        switch intent {
        case let .playTrack(startTime, duration, loop):
            isTrackPlaying = false
            playerManager.stop()

            Task { [weak self] in
                guard let self else { return }

                do {
                    let streamURL: URL

                    if let existingURL = selectedTrack.streamURL {
                        streamURL = existingURL
                    } else {
                        guard let fetchedURL = try await backend.fetchStreamURL(for: selectedTrack) else {
                            return
                        }
                        selectedTrack.streamURL = fetchedURL
                        streamURL = fetchedURL
                    }

                    playerManager.stop()
                    playerManager.load(url: streamURL)

                    playerManager.play(from: startTime, duration: duration, loop: loop) { [weak self] success in
                        self?.isTrackPlaying = success
                    }
                } catch {
                    toastMessage = "Error: \(error) :("
                }
            }

        case .stopPlaying:
            isTrackPlaying = false
            playerManager.stop()

        case .destroyPlayer:
            isTrackPlaying = false
            playerManager.cleanup()
        }
    }
}
