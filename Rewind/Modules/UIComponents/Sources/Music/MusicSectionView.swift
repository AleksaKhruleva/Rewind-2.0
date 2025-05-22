import SwiftUI
import Domain

public struct MusicSectionView: View {
    @Binding var selectedTrack: Track?
    private let onFindTrack: () -> Void
    
    public init(selectedTrack: Binding<Track?>, onFindtrack: @escaping () -> Void) {
        self._selectedTrack = selectedTrack
        self.onFindTrack = onFindtrack
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(UIComponentsStrings.Music.sectionTitle)
                .modifier(RoundFontModifier(size: 17, foregroundColor: .textSecondary))
                .padding(.leading, 15)
            
            Group {
                if let track = selectedTrack {
                    TrackRow(
                        track: track,
                        showPlayButton: false,
                        isPlaying: false,
                        isLoading: false,
                        onPlayTap: {},
                        onRowTap: { _ in
                            onFindTrack()
                        }
                    )
                } else {
                    MembersTableButton(
                        systemImageName: "music.note.list",
                        title: UIComponentsStrings.Music.addMusic,
                        imageSize: 20
                    ) {
                        onFindTrack()
                    }
                }
            }
            .padding(.vertical, 5)
            .background(Color.backgroundSecondary)
            .cornerRadius(16)
        }
    }
}
