import SwiftUI
import Domain

public struct BlurredMediaView: View {
    @Binding var isPresented: Bool
    @State private var mediaItem: MediaItem
    @State private var isTrackPlaying: Bool = false
    private var showMediaDetails: (UIImage) -> Void

    @Environment(\.showToast)
    private var showToast

    public init(
        isPresented: Binding<Bool>,
        mediaItem: MediaItem,
        showMediaDetails: @escaping (UIImage) -> Void
    ) {
        self._isPresented = isPresented
        self.mediaItem = mediaItem
        self.showMediaDetails = showMediaDetails
    }

    public var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .ignoresSafeArea()
            .onTapGesture {
                withAnimation {
                    isPresented = false
                }
            }
            .overlay {
                content
            }
    }

    private var content: some View {
        VStack {
            author

            mediaView
                .overlay {
                    RewindMediaButtonsOverlay {
                        // TODO: smth
                    } saveAction: {
                        // TODO: сделать сохранение фото или видео
                    }
                }

            actionsTable

            riskyCell
        }
        .padding(.horizontal, 8)
    }

    private var author: some View {
        HStack {
            AuthorBadgeView(
                image: UIComponentsAsset.avatar.image,
                name: "flowykk",
                date: "23.11.2024",
                track: mediaItem.track
            )
            .padding(.leading, 6)
            Spacer()
        }
        .padding(.vertical, 6)
        .background(Color.background)
        .cornerRadius(18)
    }

    private var mediaView: some View {
        MediaContentView(
            mediaItem: mediaItem,
            onSave: {},
            onLike: {},
            onToggleSound: {},
            isTrackPlaying: $isTrackPlaying
        )
    }

    private var actionsTable: some View {
        VStack(alignment: .leading, spacing: -8) {
            BlurredTableCell(
                icon: "gearshape.fill",
                title: UIComponentsStrings.Media.Blurred.title,
                needChevron: true,
                action: { /*showMediaDetails(image)*/ }
            )
        }
        .background(Color.background)
        .modifier(BlurredMediaTableModifier())
    }

    private var riskyCell: some View {
        BlurredTableCell(
            icon: "trash.fill",
            title: UIComponentsStrings.Media.Blurred.delete,
            needChevron: true,
            isRisky: true,
            action: {
                // TODO: smth
            }
        )
        .background(Color.riskyBackground)
        .modifier(BlurredMediaTableModifier())
    }

    private func saveImage(image: UIImage) {
        saveImageWithToast(image: image) { message in
            showToast(message)
        }
    }
}

struct BlurredMediaTableModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .cornerRadius(18)
    }
}
