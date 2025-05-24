import SwiftUI
import UIComponents
import Base
import Domain

public struct RewindView: View {
    @State private var viewModel: RewindViewModel
    
    // TODO: To VM
    @State private var rolls = 0
    @State private var currentIndex = 0
    @State private var filterSettingsShown = false
    @State private var isSelectGroupPresented = false
    @State private var isTrackPlaying = false
    
    private var mediaItems = [MediaItem]()
    private let router: RewindRouter
    
    @Environment(\.showToast)
    private var showToast
    
    public init(router: RewindRouter) {
        self.router = router
        viewModel = RewindViewModel()
        
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
        var track = try? JSONDecoder().decode(Track.self, from: data)
        track?.streamURL = URL(
            string: "https://cf-media.sndcdn.com/wHq5ExUUltpj.128.mp3?Policy=eyJTdGF0ZW1lbnQiOlt7IlJlc291cmNlIjoiKjovL2NmLW1lZGlhLnNuZGNkbi5jb20vd0hxNUV4VVVsdHBqLjEyOC5tcDMqIiwiQ29uZGl0aW9uIjp7IkRhdGVMZXNzVGhhbiI6eyJBV1M6RXBvY2hUaW1lIjoxNzQ4MDg2NzM5fX19XX0_&Signature=AHmH2FSsRjQsX5IxrWdvs3VJz9hQ06N8T~olBA5KuC-bxU2z1ziP2Fe1eyEQoLNm3uauVQweHCegLlE95sSyyJ0J-cnuEsMUrzo4KZFIFk~e7TykIEToaA1QVsihYD4he5tMrvDksRAAWYvYMt-tA21IsObQ84UDzD--vq~SgNhtuzpH-f9GM7R5bsuvKzOiTP6f0eDkCD9SpzhPTrQ2NJb1ZcGtkDEfnckStMQd15TNP1~hFDO4dFgMMyLzhVOf43bl1U7x4nKlqyrbpjIGHLFB62x5OIGmpa7YvYjX42vcBaPml-7eH6qEZWcUrDQnRpaEo~MOM9iYw0bz4wa7Pg__&Key-Pair-Id=APKAI6TU7MMXM5DG6EPQ"
        )
        
        mediaItems = [
            MediaItem(
                type: .imageWithMusic,
                image: UIComponentsAsset.media21.image,
                track: track
            ),
            MediaItem(
                type: .image,
                image: UIComponentsAsset.media16.image
            )
        ]
    }
    
    public var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            VStack(spacing: 10) {
                MediaTopButtons {
                    //                    router.navigateToMediaDetails(mediaImages[currentIndex])
                } onSettingsTap: {
                    filterSettingsShown = true
                }
                
                mediaView
                
                HStack {
                    author
                    Spacer()
                    RewindRollsStat(rolls: $rolls)
                }
            }
            .modifier(VStackTopOffsetModifier(topOffsetRatio: 0.15))
            .padding(.horizontal, 8)
            
            VStack {
                header
                Spacer()
            }
            
            VStack {
                Spacer()
                GalleryPreview(
                    gallerySize: 63,
                    images: [
                        // Временно
                        UIComponentsAsset.media1.image,
                        UIComponentsAsset.media2.image,
                        UIComponentsAsset.media3.image,
                        UIComponentsAsset.media4.image
                    ]
                )
                .onTapGesture {
                    router.navigateToGallery()
                }
            }
            .safeAreaPadding(20)
        }
        .onAppear {
            viewModel.set(showToast: showToast)
            Task { await viewModel.dispatch(.fetchUser) }
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $isSelectGroupPresented) {
            SelectGroupView()
                .presentationCornerRadius(30)
                .presentationDragIndicator(.visible)
                .presentationDetents([.height(450)])
        }
        .sheet(isPresented: $filterSettingsShown) {
            FilterView(title: UIComponentsStrings.Rewind.Filters.title) { settings in
                print(settings)
            }
        }
    }
    
    private var header: some View {
        RewindHeader {
            RoundImageView(image: UIComponentsAsset.media5.image, size: 44)
                .contentShape(Circle())
                .onTapGesture {
                    router.navigateToGroup()
                }
        } centerView: {
            GroupsAndLocationHeader(groupCount: 8) {
                isSelectGroupPresented = true
            } onGlobeTap: {
                router.navigateToMap()
            }
        } rightView: {
            RoundImageView(image: viewModel.user.image, size: 44)
                .contentShape(Circle())
                .onTapGesture {
                    if !viewModel.user.isEmpty {
                        router.navigateToAccount(user: viewModel.user)
                    }
                }
        }
    }
    
    private var mediaView: some View {
        MediaContentView(
            mediaItem: mediaItems[currentIndex],
            onSave: {},
            onLike: {},
            onToggleSound: {
                if !isTrackPlaying {
                    if let url = mediaItems[currentIndex].track?.streamURL {
                        AudioPlayerManager.shared.load(url: url)
                        AudioPlayerManager.shared.play(from: .zero) { isPlaying in
                            isTrackPlaying = true
                        }
                    }
                } else {
                    isTrackPlaying = false
                    AudioPlayerManager.shared.stop()
                }
            },
            isTrackPlaying: $isTrackPlaying
        )
        .onTapGesture {
            withAnimation {
                isTrackPlaying = false
                AudioPlayerManager.shared.stop()
                rolls += 1
                currentIndex = (currentIndex + 1) % mediaItems.count
            }
        }
    }
    
    private var author: some View {
        HStack {
            AuthorBadgeView(
                image: UIComponentsAsset.sasha.image,
                name: "sasha",
                date: "22.04.2025",
                track: mediaItems[currentIndex].track
            )
        }
    }
}

#Preview {
    RewindView(router: RewindRouter(appRouter: AppRouter()))
}
