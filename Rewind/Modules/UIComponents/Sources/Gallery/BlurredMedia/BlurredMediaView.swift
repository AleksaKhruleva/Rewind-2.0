import SwiftUI

public struct BlurredMediaView: View {
    @State private var image: UIImage
    @Binding var isPresented: Bool
    
    @Environment(\.showToast)
    private var showToast

    public init(image: UIImage, isPresented: Binding<Bool>) {
        self.image = image
        self._isPresented = isPresented
    }
    
    public var body: some View {
      Color.black.opacity(0.05)
          .background(BlurView())
          .ignoresSafeArea()
          .onTapGesture {
              withAnimation {
                  isPresented.toggle()
              }
          }
          .overlay(
            content
          )
    }
    
    private var content: some View {
        VStack {
            author
            
            mediaView
                .overlay {
                    RewindMediaButtonsOverlay {
                        // TODO: smth
                    } saveAction: {
                        saveImage(image: image)
                    }
                }
                
            actionsTable
                
            riskyCell
        }
    }
    
    private var author: some View {
        AuthorBadgeView(
            image: UIComponentsAsset.avatar.image,
            name: "flowykk",
            date: "23.11.2024"
        )
        .frame(width: 220)
        .padding(.vertical, 4)
        .background(.white)
        .cornerRadius(14)
    }
    
    private var mediaView: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(
                width: 380,
                height: 380
            )
            .clipShape(RoundedRectangle(cornerRadius: 40))
    }
    
    private var actionsTable: some View {
        VStack(alignment: .leading, spacing: -8) {
            BlurredTableCell(
                icon: "gearshape.fill",
                title: "Media details",
                needChevron: true,
                action: {
                    // TODO: smth
                }
            )
            
            BlurredTableCell(
                icon: "square.and.arrow.down.fill",
                title: "Save Image",
                needChevron: true,
                action: { saveImage(image: image) }
            )
        }
        .background(.white)
        .modifier(BlurredMediaTableModifier())
    }
    
    private var riskyCell: some View {
        BlurredTableCell(
            icon: "trash.fill",
            title: "Delete media",
            needChevron: true,
            isRisky: true,
            action: {
                // TODO: smth
            }
        )
        .background(UIComponentsAsset.riskyTableBackgroundColor.swiftUIColor)
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
            .frame(width: 380)
            .cornerRadius(18)
    }
}

#Preview {
    BlurredMediaView(
        image: UIComponentsAsset.media10.image,
        isPresented: Binding.constant(true))
}
