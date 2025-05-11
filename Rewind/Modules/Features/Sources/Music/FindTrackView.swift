import UIComponents
import SwiftUI
import Domain

public struct FindTrackView: View {
    @StateObject private var viewModel = FindTrackViewModel()
    
    public init() {}
    
    public var body: some View {
        VStack {
            if viewModel.tracks.isEmpty {
                progressView
            } else {
                searchField
                    .padding(.bottom, 2)
                    .padding(.horizontal)
                
                infiniteList
            }
        }
        .background(Color.background)
        .onAppear {
            viewModel.dispatch(.loadTracks)
        }
    }
    
    @ViewBuilder
    private var progressView: some View {
        Spacer()
        ProgressView("Loading top tracks")
            .modifier(RoundFontModifier(size: 15))
        Spacer()
    }
    
    private var searchField: some View {
        RewindSearchField(
            text: $viewModel.searchText,
            placeholder: "Search music"
        )
    }
    
    private func trackList(onTrackAppear: ((Track) -> Void)? = nil) -> some View {
        LazyVStack(spacing: 0) {
            ForEach(viewModel.tracks) { track in
                TrackRow(
                    track: track,
                    isPlaying: viewModel.currentlyPlayingTrackID == track.id,
                    isLoading: viewModel.currentlyLoadingTrackID == track.id
                ) {
                    viewModel.dispatch(.togglePlayback(track: track))
                }
                .onAppear {
                    onTrackAppear?(track)
                }
            }
        }
    }
    
    private var infiniteList: some View {
        VStack(alignment: .leading) {
            ScrollView(.vertical, showsIndicators: false) {
                trackList { track in
                    viewModel.dispatch(.loadMoreTracks(currentTrack: track))
                }
                
                if viewModel.isLoadingMore {
                    loadingMoreProgressView
                } else if viewModel.hasReachedEnd {
                    endNote
                }
            }
        }
    }
    
    private var loadingMoreProgressView: some View {
        ProgressView("Loading more...")
            .modifier(RoundFontModifier(size: 15))
            .padding(.vertical, 8)
    }
    
    private var endNote: some View {
        RewindNoteTextView(text: UIComponentsStrings.Note.end)
            .padding(.vertical, 8)
    }
}
