import SwiftUI

struct LeaderboardRowView: View {
    let rank: Int
    let member: Member
    let count: Int
    let counterType: CounterType
    
    var body: some View {
        HStack {
            Text("\(rank)")
                .modifier(RoundFontModifier(size: 16, foregroundColor: .white))
                .padding(.trailing, 8)
            
            Image(uiImage: member.avatar)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 48, height: 48)
                .cornerRadius(12)
            
            Text(member.name)
                .modifier(RoundFontModifier(size: 16, foregroundColor: .white))
                .lineLimit(1)
                .truncationMode(.tail)
            
            Spacer()
            
            Text("\(count) \(counterType)")
                .modifier(RoundFontModifier(size: 14, foregroundColor: .white))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
    }
}
