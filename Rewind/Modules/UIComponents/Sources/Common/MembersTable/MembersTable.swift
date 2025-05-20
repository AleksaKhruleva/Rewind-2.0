import SwiftUI

public struct MembersTable: View {
    private let title: String
    private let members: [Member]
    private let isShortened: Bool
    private let onAddMemberTap: () -> Void
    
    public init(
        title: String = "Members",
        members: [Member],
        isShortened: Bool,
        onAddMemberTap: @escaping () -> Void
    ) {
        self.title = title
        self.members = members
        self.isShortened = isShortened
        self.onAddMemberTap = onAddMemberTap
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
                    MembersTableCell(member: member) {
                        // TODO: go to MemberDetails
                        print("go")
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
                        print("Show all members")
                    }
                }
            }
            .padding(.vertical, 5)
            .background(Color.backgroundSecondary)
            .cornerRadius(24)
        }
    }
}
