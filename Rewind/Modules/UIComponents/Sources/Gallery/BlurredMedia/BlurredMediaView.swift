import SwiftUI
import Domain

public struct BlurredMediaView: View {
    @Binding var isPresented: Bool
    @State private var galleryItem: GalleryItem
    @State private var isTrackPlaying: Bool = false
    private var onDelete: (GalleryItem) -> Void
    private var showMediaDetails: (GalleryItem) -> Void

    @Environment(\.showToast)
    private var showToast

    public init(
        isPresented: Binding<Bool>,
        galleryItem: GalleryItem,
        onDelete: @escaping (GalleryItem) -> Void,
        showMediaDetails: @escaping (GalleryItem) -> Void
    ) {
        self._isPresented = isPresented
        self.galleryItem = galleryItem
        self.onDelete = onDelete
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
                imageURL: galleryItem.memory.userImage,
                name: galleryItem.memory.username,
                date: galleryItem.memory.createdAt,
                track: galleryItem.memory.track
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
            mediaItem: galleryItem.memory,
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
                action: { showMediaDetails(galleryItem) }
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
                onDelete(galleryItem)
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
