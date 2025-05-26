import SwiftUI
import AVFoundation
import Domain
import Base

public struct MediaContentView: View {
    private let mediaItem: MediaItem
    private let cornerRadius: CGFloat
    private let onSave: () -> Void
    private let onLike: () -> Void
    private let onToggleSound: () -> Void
    @Binding var isTrackPlaying: Bool

    // Video player state
    @State private var player: AVPlayer?
    @State private var playerItem: AVPlayerItem?
    @State private var statusObserver: NSKeyValueObservation?

    @State private var isVideoReadyToPlay = false
    @State private var isVideoPlaying = false
    @State private var isVideoMuted = true
    @State private var shouldSeekToStartTime = false

    public init(
        mediaItem: MediaItem,
        cornerRadius: CGFloat = 35,
        onSave: @escaping () -> Void,
        onLike: @escaping () -> Void,
        onToggleSound: @escaping () -> Void,
        isTrackPlaying: Binding<Bool>
    ) {
        self.mediaItem = mediaItem
        self.cornerRadius = cornerRadius
        self.onSave = onSave
        self.onLike = onLike
        self.onToggleSound = onToggleSound
        self._isTrackPlaying = isTrackPlaying
    }

    public var body: some View {
        ZStack {
            switch mediaItem.mediaType {
            case .image:
                imageContent
            case .video:
                videoContent
            case .quote:
                EmptyView()
            }
        }
        .overlay {
            RewindMediaButtonsOverlay(
                likeAction: onLike,
                saveAction: onSave
            )
        }
    }

    private var imageContent: some View {
        SquareAsyncMedia(url: mediaItem.mediaURL, type: .image)
            .overlay(alignment: .topTrailing) {
                if mediaItem.track != nil {
                    Button(action: {}) {
                        ZStack {
                            Image(systemName: "speaker.wave.2.fill").opacity(isTrackPlaying ? 1 : 0)
                            Image(systemName: "speaker.slash.fill").opacity(isTrackPlaying ? 0 : 1)
                        }
                        .modifier(RoundFontModifier(size: 14, weight: .regular, foregroundColor: .white))
                        .padding(7.5)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                    }
                    .padding(12)
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            onToggleSound()
                            print("toggle sound")
                        }
                    )
                }
            }
    }

    private var videoContent: some View {
        ZStack {
            SquareAsyncMedia(url: mediaItem.mediaURL, type: .video)

            if let player = player {
                CustomPlayerView(
                    isPlaying: $isVideoPlaying,
                    isMuted: $isVideoMuted,
                    shouldSeekToStartTime: $shouldSeekToStartTime,
                    player: player,
                    startTime: .zero,
                    onSeekComplete: {}
                )
                .opacity(isVideoReadyToPlay ? 1 : 0)
                .animation(.easeInOut(duration: 0.25), value: isVideoReadyToPlay)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            resetPlayer()
        }
    }

    private func setupPlayer() {
        guard let url = mediaItem.mediaURL else { return }

        let item = AVPlayerItem(url: url)
        playerItem = item
        player = AVPlayer(playerItem: item)

        statusObserver = item.observe(\.status, options: [.initial, .new]) { item, _ in
            if item.status == .readyToPlay {
                print("Ready to play")
                isVideoReadyToPlay = true
                isVideoPlaying = true
            } else if item.status == .failed {
                print("Video failed: \(item.error?.localizedDescription ?? "Unknown error")")
            } else if item.status == .unknown {
                print("Unknown status")
            }
        }

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak player] _ in
            player?.seek(to: .zero)
            isVideoPlaying = false
        }
    }

    private func resetPlayer() {
        player?.pause()
        player = nil
        playerItem = nil
        statusObserver = nil
        NotificationCenter.default.removeObserver(self)
    }
}
