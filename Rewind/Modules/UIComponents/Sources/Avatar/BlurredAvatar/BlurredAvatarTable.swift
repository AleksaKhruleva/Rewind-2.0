import SwiftUI

struct BlurredAvatarTable: View {
    @Binding var showPicker: Bool
    var saveImage: () -> Void
    
    public var body: some View {
        VStack(alignment: .leading, spacing: -8) {
            BlurredTableCell(
                icon: "photo",
                title: UIComponentsStrings.BlurredAvatar.setImage,
                action: {
                    showPicker = true
                }
            )
            
            BlurredTableCell(
                icon: "square.and.arrow.down.fill",
                title: UIComponentsStrings.BlurredAvatar.saveImage,
                action: saveImage
            )
        }
        .frame(width: 200)
        .background(.white)
        .cornerRadius(18)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2).ignoresSafeArea(edges: .all)
        
        BlurredAvatarTable(showPicker: Binding.constant(false), saveImage: {})
    }
}
