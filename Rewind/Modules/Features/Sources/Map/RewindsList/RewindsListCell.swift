import SwiftUI
import UIComponents

struct RewindsListCell: View {
    var rewind: RewindOnMap
    
    var body: some View {
        HStack {
            Rectangle().toSquare(rewind.image, cornerRadius: 20)
                .frame(90)
                .padding(.trailing, 16)
            
            VStack(alignment: .leading) {
                HStack(spacing: 12) {
                    Text(UIComponentsStrings.Map.RewindsList.author)
                        .modifier(RoundFontModifier(size: 17, weight: .bold))
                                              
                    HeaderBadgeView(
                        image: UIComponentsAsset.avatar.image,
                        text: "flowykkkkkkkk"
                    )
                    .lineLimit(1)
                }
                
                Text("23.11.2024").modifier(RoundFontModifier(size: 15, foregroundColor: .textTertiary))
            }
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}
