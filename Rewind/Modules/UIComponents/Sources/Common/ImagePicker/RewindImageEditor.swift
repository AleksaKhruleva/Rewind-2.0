import SwiftUI
import PhotosUI

enum CropType {
    case rectangle
    case circle
}

struct RewindImageEditor: View {
    @Binding var image: UIImage?
    var cropType: CropType
    var onCrop: (UIImage?, Bool) -> ()
    
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @GestureState private var isInteracting: Bool = false
    
    @Environment(\.dismiss)
    private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                ZStack {
                    imageView
                    imageMask
                }
                .ignoresSafeArea()

                header
            }
            .background(.white)
        }
    }
    
    var header: some View {
        RewindHeader {
            RewindButton(type: .leftChevron) { dismiss() }
        } centerView: {
            Text("Image Editor")
                .modifier(RoundFontModifier(size: AccountConstants.defaultFontSize, weight: .bold))
                .foregroundColor(.textPrimary)
        } rightView: {
            RewindButton(type: .checkmark) {
                let renderer = ImageRenderer(content: imageView)
                renderer.proposedSize = .init(CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width))
                if let image = renderer.uiImage {
                    onCrop(image, true)
                } else {
                    onCrop(nil, false)
                }
                dismiss()
            }
        }
    }
    
    var imageMask: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            Color.white.opacity(0.8)
                .overlay(
                    Rectangle()
                        .frame(width: width, height: width)
                        // TODO: 40 to constants
                        .cornerRadius(cropType == .circle ? width / 2 : 40)
                        .blendMode(.destinationOut)
                )
                .compositingGroup()
                .allowsHitTesting(false)
        }
    }
    
    @ViewBuilder
    var imageView: some View {
        let cropSize = CGSize(
            width: UIScreen.main.bounds.width,
            height: UIScreen.main.bounds.width
        )
        
        GeometryReader {
            let size = $0.size
            
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .overlay {
                        GeometryReader { proxy in
                            let rect = proxy.frame(in: .named("CROPVIEW"))
                            
                            Color.clear
                                .onChange(of: isInteracting) { _, newValue in
                                    withAnimation(.easeInOut) {
                                        if rect.minX > 0 {
                                            offset.width = (offset.width - rect.minX)
                                            haptics(.medium)
                                        }
                                        if rect.minY > 0 {
                                            offset.height = (offset.height - rect.minY)
                                            haptics(.medium)
                                        }
                                        if rect.maxX < size.width {
                                            offset.width = (rect.minX - offset.width)
                                            haptics(.medium)
                                        }
                                        if rect.maxY < size.height {
                                            offset.height = (rect.minY - offset.height)
                                            haptics(.medium)
                                        }
                                    }
                                    if !newValue {
                                        lastOffset = offset
                                    }
                                }
                        }
                    }
                    .frame(width: size.width, height: size.height)
            }
        }
        .scaleEffect(scale)
        .offset(offset)
        .coordinateSpace(name: "CROPVIEW")
        .gesture(
            DragGesture()
                .updating($isInteracting, body: { _, out, _ in
                    out = true
                }).onChanged { value in
                    let translation = value.translation
                    offset = CGSize(
                        width: translation.width + lastOffset.width,
                        height: translation.height + lastOffset.height
                    )
                }
        )
        .gesture(
            MagnificationGesture()
                .updating($isInteracting, body: { _, out, _ in
                    out = true
                }).onChanged({ value in
                    let updatedScale = value + lastScale
                    scale = (updatedScale < 1 ? 1 : updatedScale)
                }).onEnded({ value in
                    withAnimation(.easeInOut) {
                        if scale < 1 {
                            scale = 1
                            lastScale = 0
                        } else {
                            lastScale = scale - 1
                        }
                    }
                })
        )
        .frame(width: cropSize.width, height: cropSize.height)
    }
}
