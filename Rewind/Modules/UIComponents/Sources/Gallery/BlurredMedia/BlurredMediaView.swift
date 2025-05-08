import SwiftUI

public struct BlurredMediaView: View {
    @State private var image: UIImage
    @Binding var isPresented: Bool
    var showMediaDetails: (UIImage) -> Void
    
    @Environment(\.showToast)
    private var showToast

    public init(
        image: UIImage,
        isPresented: Binding<Bool>,
        showMediaDetails: @escaping (UIImage) -> Void
    ) {
        self.image = image
        self._isPresented = isPresented
        self.showMediaDetails = showMediaDetails
    }
    
    public var body: some View {
      Color.black.opacity(0.05)
          .background(BlurView())
          .ignoresSafeArea()
          .onTapGesture {
              withAnimation {
                  isPresented = false
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
        .padding(.horizontal, 8)
    }
    
    private var author: some View {
        AuthorBadgeView(
            image: UIComponentsAsset.avatar.image,
            name: "flowykk",
            date: "23.11.2024"
        )
        .frame(width: 220)
        .padding(.vertical, 4)
        .background(Color.background)
        .cornerRadius(14)
    }
    
    private var mediaView: some View {
        Rectangle().toSquare(image, cornerRadius: 40)
    }
    
    private var actionsTable: some View {
        VStack(alignment: .leading, spacing: -8) {
            BlurredTableCell(
                icon: "gearshape.fill",
                title: UIComponentsStrings.Media.Blurred.title,
                needChevron: true,
                action: { showMediaDetails(image) }
            )
            
            BlurredTableCell(
                icon: "square.and.arrow.down.fill",
                title: UIComponentsStrings.Media.Blurred.save,
                needChevron: true,
                action: { saveImage(image: image) }
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
