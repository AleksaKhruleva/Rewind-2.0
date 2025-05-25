import SwiftUI
import UIComponents
import Domain

public struct ImageUploadingView: View {
    @State private var viewModel: ImageUploadingViewModel
    var onSave: (LoadedMedia) -> Void

    @Environment(\.showToast)
    private var showToast
    @Environment(\.dismiss)
    private var dismiss

    public init(media: LoadedMedia? = nil, onSave: @escaping (LoadedMedia) -> Void) {
        viewModel = .init(loadedMedia: media)
        self.onSave = onSave
    }

    public var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    if let image = viewModel.image {
                        Rectangle().toSquare(image)
                            .clipShape(RoundedRectangle(cornerRadius: 40))
                            .padding(.horizontal, 8)
                    } else {
                        emptyImageContent
                            .onTapGesture {
                                viewModel.dispatch(.viewGallery)
                            }
                            .padding(.horizontal, 8)
                    }

                    Group {
                        musicSection

                        TagsSectionView(tags: viewModel.loadedMediaTagsBinding)
                            .padding(.horizontal, 8)
                    }.disabledWithOpacity(!viewModel.ready)
                }
            }
        }
        .background(Color.background)
        .safeAreaInset(edge: .bottom) {
            continueButton
        }
        .customImagePicker(show: $viewModel.imagePickerPresented, cropType: .rectangle, croppedImage: Binding {
            return viewModel.image
        } set: { newImage in
            viewModel.dispatch(.changeImage(newImage, .hard))
        })
        .fullScreenCover(isPresented: $viewModel.imageEditorPresented, onDismiss: {
            viewModel.dispatch(.resumePlayback)
        }) {
            RewindImageEditor(image: viewModel.initialImage, cropType: .rectangle) { croppedImage, status in
                if status {
                    viewModel.dispatch(.changeImage(croppedImage))
                }
            }
        }
        .sheet(isPresented: $viewModel.findTrackViewPresented, onDismiss: {
            viewModel.dispatch(.resumePlayback)
        }) {
            FindTrackView { selectedTrack in
                viewModel.dispatch(.trackSelected(selectedTrack))
            }
        }
    }

    private var header: some View {
        RewindHeader {
            RewindButton(type: .leftChevron) { dismiss() }
        } rightView: {
            HStack {
                RewindButton(type: .photo) {
                    viewModel.dispatch(.viewGallery)
                }
                RewindButton(type: .crop) {
                    viewModel.dispatch(.cropImage)
                }
            }
        }
    }

    private var emptyImageContent: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 40)
                .fill(Color.backgroundSecondary)
                .aspectRatio(1, contentMode: .fit)

            VStack {
                Image(systemName: "photo")
                    .font(.system(size: 130))
                    .foregroundColor(.textSecondary)

                Text(UIComponentsStrings.Video.hint)
                    .modifier(RoundFontModifier(size: 15, weight: .bold))
            }
        }
    }

    private var musicSection: some View {
        VStack {
            MusicSectionView(
                selectedTrack: $viewModel.selectedTrack) {
                    viewModel.dispatch(.findTrack)
                }
                .padding(.horizontal, 8)

            if let selectedTrack = viewModel.selectedTrack {
                ChooseTrackPieceView(
                    shouldPlay: $viewModel.isSelectedTrackPlaying,
                    startTime: $viewModel.selectedStartTime,
                    selectorDuration: $viewModel.selectedDuration,
                    selectedTrack: selectedTrack,
                    onTrashTap: {
                        withAnimation {
                            viewModel.selectedTrack = nil
                        }
                    }
                )
                .id(selectedTrack.id)
            }
        }
    }

    private var continueButton: some View {
        GradientButton(title: "Save image", width: .given(200)) {
            if let loadedMedia = viewModel.loadedMedia {
                // TODO: delete later
                let trackInfo = (
                    viewModel.selectedTrack?.id,
                    viewModel.selectedStartTime,
                    viewModel.selectedDuration
                )

                print(trackInfo)

                onSave(loadedMedia)
                dismiss()
            }
        }.disabledWithOpacity(!viewModel.ready)
    }
}
