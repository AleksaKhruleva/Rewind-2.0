import SwiftUI
import Domain

public struct GroupsTable: View {
    private let title: String
    private let groups: [RewindGroup]
    private let onAddGroupTap: () -> Void
    private let onGroupTap: (RewindGroup) -> Void

    public init(
        title: String = "Groups",
        groups: [RewindGroup],
        onAddGroupTap: @escaping () -> Void,
        onGroupTap: @escaping (RewindGroup) -> Void
    ) {
        self.title = title
        self.groups = groups
        self.onAddGroupTap = onAddGroupTap
        self.onGroupTap = onGroupTap
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .modifier(
                    RoundFontModifier(size: 17, foregroundColor: .textSecondary))
                .padding(.leading, 15)

            VStack(alignment: .leading, spacing: 0) {
                addGroupButton

                ForEach(groups) { group in
                    GroupsTableCell(group: group) { _ in
                        onGroupTap(group)
                    }
                }
            }
            .padding(.vertical, 5)
            .background(Color.backgroundSecondary)
            .cornerRadius(24)
        }
    }

    private var addGroupButton: some View {
        Button {
            onAddGroupTap()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.2.badge.plus.fill")
                    .modifier(RoundFontModifier(size: 25))
                    .frame(width: 34, height: 34)

                Text(UIComponentsStrings.Groups.addGroup)
                    .modifier(RoundFontModifier(
                        size: 16,
                        weight: .bold,
                        foregroundColor: .textPrimary
                    ))

                Spacer()

                Image(systemName: "chevron.right")
                    .modifier(RoundFontModifier(size: 14))
                    .padding(.trailing, 3)
            }
            .frame(height: 35)
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
    }
}
