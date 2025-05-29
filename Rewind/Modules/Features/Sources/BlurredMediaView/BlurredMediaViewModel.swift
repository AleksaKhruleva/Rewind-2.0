import SwiftUI
import Domain
import Base

@MainActor @Observable
final class BlurredMediaViewModel {
    enum Intent {
        case toggleTrackPlaying
        case killPlayer
    }

    var isTrackPlaying = false
    var isVideoPlaying = true
    private let galleryItem: GalleryItem
    private let audioManager: AudioPlayerManager

    init(galleryItem: GalleryItem) {
        self.galleryItem = galleryItem
        audioManager = AudioPlayerManager.shared
    }

    func dispatch(_ intent: Intent) {
        switch intent {
        case .toggleTrackPlaying:
            if !isTrackPlaying {
                guard let track = galleryItem.memory.lightTrack else {
                    return
                }
                guard let streamURL = track.streamURL else {
                    return
                }
                audioManager.load(url: streamURL)
                audioManager.play(
                    from: track.startTime,
                    duration: track.duration,
                    loop: true
                ) { [weak self] isPlaying in
                    self?.isTrackPlaying = isPlaying
                }
            } else {
                isTrackPlaying = false
                audioManager.stop()
            }
        case .killPlayer:
            isTrackPlaying = false
            audioManager.cleanup()
        }
    }
}
