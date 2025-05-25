import SwiftUI
import Domain

public struct MembersTable: View {
    private let title: String
    private let members: [Member]
    private let isShortened: Bool
    private let onAddMemberTap: () -> Void
    private let onMemberTap: (Member) -> Void
    private let onShowAllMembersTap: (() -> Void)?

    public init(
        title: String = "Members",
        members: [Member],
        isShortened: Bool,
        onAddMemberTap: @escaping () -> Void,
        onMemberTap: @escaping (Member) -> Void,
        onShowAllMembersTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.members = members
        self.isShortened = isShortened
        self.onAddMemberTap = onAddMemberTap
        self.onMemberTap = onMemberTap
        self.onShowAllMembersTap = onShowAllMembersTap
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .modifier(
                    RoundFontModifier(size: 17, foregroundColor: .textSecondary))
                .padding(.leading, 15)

            VStack(alignment: .leading, spacing: 0) {
                MembersTableButton(
                    systemImageName: "person.fill.badge.plus",
                    title: UIComponentsStrings.Group.Members.add,
                    imageSize: 25
                ) {
                    onAddMemberTap()
                }

                ForEach(members) { member in
                    MemberRow(member: member) { member in
                        onMemberTap(member)
                    } onRemove: {
                        // TODO: show remove confirmation
                        print("remove")
                    }
                }

                if isShortened {
                    MembersTableButton(
                        systemImageName: "eye.fill",
                        title: UIComponentsStrings.Group.Members.count(membersForTest.count),
                        imageSize: 20
                    ) {
                        onShowAllMembersTap?()
                    }
                }
            }
            .padding(.vertical, 5)
            .background(Color.backgroundSecondary)
            .cornerRadius(24)
        }
    }
}
