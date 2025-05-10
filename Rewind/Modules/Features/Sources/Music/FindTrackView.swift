import UIComponents
import SwiftUI

public struct FindTrackView: View {
    @StateObject private var viewModel = FindTrackViewModel()
    
    public init() {}
    
    public var body: some View {
        VStack {
            header
            
            Group {
                searchField
                    .padding(.bottom, 2)
                
                if viewModel.tracks.isEmpty {
                    VStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        ForEach(viewModel.tracks) { track in
                            TrackRow(
                                track: track,
                                isPlaying: viewModel.currentlyPlayingTrackID == track.id,
                                isLoading: viewModel.currentlyLoadingTrackID == track.id
                            ) {
                                viewModel.dispatch(.togglePlayback(track: track))
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .background(Color.background)
        .onAppear {
            viewModel.dispatch(.loadTracks)
        }
    }
    
    private var header: some View {
        RewindHeader(leftView: {
            RewindButton(type: .leftChevron) {}
        })
    }
    
    private var searchField: some View {
        RewindSearchField(
            text: $viewModel.searchText,
            placeholder: "Search music"
        )
    }
}
