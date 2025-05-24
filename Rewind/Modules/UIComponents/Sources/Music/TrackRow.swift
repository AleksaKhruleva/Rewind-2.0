import Domain
import SwiftUI

private let imageSize: CGFloat = 50

public struct TrackRow: View {
    private let track: Track
    private let showPlayButton: Bool
    private let isPlaying: Bool
    private let isLoading: Bool
    private let onPlayTap: () -> Void
    private let onRowTap: (Track) -> Void

    public init(
        track: Track,
        showPlayButton: Bool = true,
        isPlaying: Bool,
        isLoading: Bool,
        onPlayTap: @escaping () -> Void,
        onRowTap: @escaping (Track) -> Void
    ) {
        self.track = track
        self.showPlayButton = showPlayButton
        self.isPlaying = isPlaying
        self.isLoading = isLoading
        self.onPlayTap = onPlayTap
        self.onRowTap = onRowTap
    }

    public var body: some View {
        HStack {
            HStack(spacing: 12) {
                AsyncImage(url: track.artworkURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        ZStack {
                            Color.textTertiary
                            Image(systemName: "music.note")
                                .resizable()
                                .scaledToFit()
                                .padding(12)
                                .foregroundColor(Color.background)
                        }
                    }
                }
                .frame(width: imageSize, height: imageSize)
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 5) {
                    Text(track.title)
                        .modifier(RoundFontModifier(size: 15))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(
                            maxWidth: UIScreen.main.bounds.width / 1.5,
                            alignment: .leading
                        )

                    HStack {
                        Text(track.artist)
                            .lineLimit(1)
                            .truncationMode(.tail)

                        Image(systemName: "circle.fill")
                            .font(.system(size: 3))
                            .frame(width: 1)

                        Text(track.durationString)
                    }
                    .modifier(RoundFontModifier(size: 13, foregroundColor: .textTertiary))
                }

                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onRowTap(track)
            }

            if showPlayButton {
                if isLoading {
                    ProgressView()
                } else {
                    Button {
                        onPlayTap()
                    } label: {
                        Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                            .modifier(RoundFontModifier(size: 18))
                    }
                }
            } else {
                Image(systemName: "chevron.right")
                    .modifier(RoundFontModifier(size: 14))
                    .padding(.trailing, 3)
                    .onTapGesture {
                        onRowTap(track)
                    }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, showPlayButton ? 16 : 8)
        .background(
            isPlaying ? Color.backgroundSecondary : .clear
        )
    }
}
