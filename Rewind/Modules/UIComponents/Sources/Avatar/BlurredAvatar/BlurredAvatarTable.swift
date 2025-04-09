import SwiftUI

struct BlurredAvatarTable: View {
    @Binding var showPicker: Bool
    var saveImage: () -> Void
    
    public var body: some View {
        VStack(alignment: .leading, spacing: -8) {
            BlurredTableCell(
                icon: "photo",
                title: "Set new image",
                action: {
                    showPicker = true
                }
            )
            
            BlurredTableCell(
                icon: "square.and.arrow.down.fill",
                title: "Save Image",
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
