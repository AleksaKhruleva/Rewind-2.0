import SwiftUI
import Domain

struct MemberRow: View {
    private let member: Member
    private let onTap: (Member) -> Void
    private let onRemove: () -> Void

    init(
        member: Member,
        onTap: @escaping (Member) -> Void,
        onRemove: @escaping () -> Void
    ) {
        self.member = member
        self.onTap = onTap
        self.onRemove = onRemove
    }

    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(uiImage: member.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 34, height: 34)
                    .clipShape(Circle())

                Text(member.name)
                    .modifier(RoundFontModifier(size: 16, foregroundColor: .textPrimary))

                if member.isUser {
                    Text(UIComponentsStrings.Group.Members.you)
                        .modifier(
                            RoundFontModifier(size: 14, foregroundColor: .textTertiary)
                        )
                        .padding(.leading, -8)
                }

                Spacer()
            }
            .frame(height: 42)
            .padding(.leading, 14)
            .contentShape(Rectangle())
            .onTapGesture {
                onTap(member)
            }

            Group {
                if member.isOwner {
                    Image(systemName: "star.fill")
                        .modifier(RoundFontModifier(size: 14, foregroundColor: .pinkPrimary))
                        .padding(.trailing, -2)
                } else {
                    Button(action: onRemove) {
                        Image(systemName: "xmark")
                            .modifier(RoundFontModifier(size: 14))
                    }
                }
            }
            .frame(height: 42)
            .padding(.horizontal, 14)
        }
        .padding(.vertical, 5)
    }
}
