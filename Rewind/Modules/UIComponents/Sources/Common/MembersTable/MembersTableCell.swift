import SwiftUI

struct MembersTableCell: View {
    private let member: Member
    private let onTap: () -> Void
    private let onRemove: () -> Void
    
    init(
        member: Member,
        onTap: @escaping () -> Void,
        onRemove: @escaping () -> Void
    ) {
        self.member = member
        self.onTap = onTap
        self.onRemove = onRemove
    }
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(uiImage: member.avatar)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 34, height: 34)
                    .clipShape(Circle())
                
                Text(member.name)
                    .modifier(RoundFontModifier(size: 16, foregroundColor: .textPrimary))
                
                if member.isUser {
                    Text("(You)")
                        .modifier(
                            RoundFontModifier(size: 14, foregroundColor: .textTertiary)
                        )
                        .padding(.leading, -8)
                }
                
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
            
            if member.isOwner {
                Image(systemName: "star.fill")
                    .modifier(RoundFontModifier(size: 14, foregroundColor: .pinkPrimary))
            } else {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .modifier(RoundFontModifier(size: 14))
                        .padding(.trailing, 1)
                }
                .contentShape(Circle())
            }
        }
        .frame(height: 42)
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
    }
}

#Preview {
    ForEach(membersForTest) { member in
        MembersTableCell(member: member) {
            print("Open member details screen")
        } onRemove: {
            print("Remove \(member.name)?")
        }
    }
}
