import SwiftUI
import UIComponents
import Domain

public struct ImageUploadingView: View {
    @State var viewModel: ImageUploadingViewModel
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
                    } else {
                        emptyImageContent
                            .onTapGesture {
                                viewModel.dispatch(.viewGallery)
                            }
                    }
                    
                    Group {
                        musicSection
                        
                        TagsSectionView(tags: viewModel.loadedMediaTagsBinding)
                    }.disabledWithOpacity(!viewModel.ready)
                }
            }
        }
        .padding(.horizontal, 8)
        .safeAreaInset(edge: .bottom) {
            continueButton
        }
        .customImagePicker(show: $viewModel.imagePickerPresented, cropType: .rectangle, croppedImage: Binding {
            return viewModel.image
        } set: { newImage in
            viewModel.dispatch(.changeImage(newImage, .hard))
        }) {}
        .fullScreenCover(isPresented: $viewModel.imageEditorPresented) {
            RewindImageEditor(image: viewModel.initialImage, cropType: .rectangle) { croppedImage, status in
                if status {
                    viewModel.dispatch(.changeImage(croppedImage))
                }
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
        VStack(alignment: .leading, spacing: 5) {
            Text(UIComponentsStrings.Music.sectionTitle)
                .modifier(RoundFontModifier(size: 17, foregroundColor: .textSecondary))
                .padding(.leading, 15)
            VStack(alignment: .leading, spacing: 5) {
                MembersTableButton(
                    systemImageName: "music.note.list",
                    title: UIComponentsStrings.Music.addMusic,
                    imageSize: 20) {
                        // TODO: show add music view
                    }
            }
            .padding(.vertical, 5)
            .background(Color.backgroundSecondary)
            .cornerRadius(24)
        }
    }
    
    private var continueButton: some View {
        GradientButton(title: "Save image", width: .given(200)) {
            if let loadedMedia = viewModel.loadedMedia {
                onSave(loadedMedia)
                dismiss()
            }
        }.disabledWithOpacity(!viewModel.ready)
    }
}
