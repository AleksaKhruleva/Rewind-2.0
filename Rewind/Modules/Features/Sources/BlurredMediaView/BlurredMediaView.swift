import SwiftUI
import Domain
import UIComponents

struct BlurredMediaView: View {
    @Binding var isPresented: Bool
    @State private var galleryItem: GalleryItem
    @State private var viewModel: BlurredMediaViewModel
    private var onDelete: (GalleryItem) -> Void
    private var onLike: (GalleryItem, Bool) -> Void
    private var showMediaDetails: (GalleryItem) -> Void

    @Environment(\.showToast)
    private var showToast

    init(
        isPresented: Binding<Bool>,
        galleryItem: GalleryItem,
        onDelete: @escaping (GalleryItem) -> Void,
        onLike: @escaping (GalleryItem, Bool) -> Void,
        showMediaDetails: @escaping (GalleryItem) -> Void
    ) {
        self._isPresented = isPresented
        self.galleryItem = galleryItem
        self.onDelete = onDelete
        self.onLike = onLike
        self.showMediaDetails = showMediaDetails
        viewModel = BlurredMediaViewModel(galleryItem: galleryItem)
    }

    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .ignoresSafeArea()
            .onTapGesture {
                viewModel.dispatch(.killPlayer)
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
                track: galleryItem.memory.lightTrack
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
            galleryItem: galleryItem,
            onSave: {},
            onLike: { liked in
                onLike(galleryItem, liked)
            },
            onToggleSound: {
                viewModel.dispatch(.toggleTrackPlaying)
            },
            isTrackPlaying: $viewModel.isTrackPlaying
        )
    }

    private var actionsTable: some View {
        VStack(alignment: .leading, spacing: -8) {
            BlurredTableCell(
                icon: "gearshape.fill",
                title: UIComponentsStrings.Media.Blurred.title,
                needChevron: true,
                action: {
                    viewModel.dispatch(.killPlayer)
                    showMediaDetails(galleryItem)
                }
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
