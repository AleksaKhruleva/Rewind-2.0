import Domain
import SwiftUI

private let imageSize: CGFloat = 50

public struct TrackRow: View {
    private let track: Track
    private let isPlaying: Bool
    private let isLoading: Bool
    private let onPlayTap: () -> Void
    
    public init(
        track: Track,
        isPlaying: Bool,
        isLoading: Bool,
        onPlayTap: @escaping () -> Void
    ) {
        self.track = track
        self.isPlaying = isPlaying
        self.isLoading = isLoading
        self.onPlayTap = onPlayTap
    }
    
    public var body: some View {
        HStack {
            AsyncImage(url: track.artworkURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                default:
                    ZStack {
                        Color.textSecondary
                        Image(systemName: "music.note")
                            .resizable()
                            .scaledToFit()
                            .padding(12)
                            .foregroundColor(Color.textPrimary)
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
                .modifier(RoundFontModifier(size: 13, foregroundColor: .textTertiary.opacity(0.6)))
            }
            
            Spacer()
            
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
        }
        .padding(.vertical, 4)
    }
}
