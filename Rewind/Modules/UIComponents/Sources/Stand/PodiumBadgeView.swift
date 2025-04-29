import SwiftUI

struct PodiumBadgeView: View {
    let rank: Int
    let member: Member
    let imageSize: CGFloat
    let count: Int
    let counterType: CounterType
    let badgeSize: CGFloat
    let badgeColor: Color
    
    var body: some View {
        VStack(spacing: 5) {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: member.avatar)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: imageSize, height: imageSize)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white, lineWidth: 3)
                    )
                
                Text("\(rank)")
                    .modifier(RoundFontModifier(size: badgeSize * 0.5, foregroundColor: .white))
                    .frame(width: badgeSize, height: badgeSize)
                    .background(Circle().fill(badgeColor))
                    .overlay(
                        Circle().stroke(Color.white, lineWidth: 3)
                    )
                    .offset(x: 7, y: -7)
            }
            
            Text(member.name)
                .modifier(RoundFontModifier(size: 16, foregroundColor: .white))
                .padding(.top, 4)
            
            Text("\(count) \(counterType)")
                .modifier(RoundFontModifier(size: 12, foregroundColor: UIComponentsAsset.appIconLightGray.swiftUIColor))
        }
        .padding()
    }
    
    private var cornerRadius: CGFloat {
        imageSize * 0.25
    }
}
