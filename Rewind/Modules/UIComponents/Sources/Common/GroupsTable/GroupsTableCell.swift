import SwiftUI
import Domain

struct GroupsTableCell: View {
    private let group: RewindGroup
    private let onTap: (RewindGroup) -> Void

    init(
        group: RewindGroup,
        onTap: @escaping (RewindGroup) -> Void
    ) {
        self.group = group
        self.onTap = onTap
    }

    var body: some View {
        Button {
            onTap(group)
        } label: {
            HStack {
                HStack(spacing: 12) {
                    Image(uiImage: group.image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 34, height: 34)
                        .clipShape(Circle())

                    Text(group.name)
                        .modifier(RoundFontModifier(size: 16, foregroundColor: .textPrimary))

                    Spacer()
                }
                .frame(height: 42)
                .padding(.leading, 14)
                .contentShape(Rectangle())
            }
            .padding(.vertical, 5)
        }
    }
}
