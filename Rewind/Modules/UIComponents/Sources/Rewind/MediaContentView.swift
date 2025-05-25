import SwiftUI
import Domain

public struct MediaContentView: View {
    private let mediaItem: MediaItem
    private let cornerRadius: CGFloat
    private let onSave: () -> Void
    private let onLike: () -> Void
    private let onToggleSound: () -> Void
    @Binding var isTrackPlaying: Bool

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
            switch mediaItem.type {
            case .image:
                Rectangle()
                    .toSquare(mediaItem.image, cornerRadius: cornerRadius)
            case .imageWithMusic:
                Rectangle()
                    .toSquare(mediaItem.image, cornerRadius: cornerRadius)
                    .overlay(alignment: .topTrailing) {
                        if mediaItem.type == .imageWithMusic {
                            Button {
                                onToggleSound()
                            } label: {
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
                        }
                    }
            case .video:
                Text("Not Implemented Yet")
            }
        }
        .overlay {
            RewindMediaButtonsOverlay(
                likeAction: onLike,
                saveAction: onSave
            )
        }
    }
}
