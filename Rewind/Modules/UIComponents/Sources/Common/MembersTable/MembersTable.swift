import SwiftUI

public struct MembersTable: View {
    private let title: String
    private let members: [Member]
    private let isShortened: Bool
    
    public init(title: String = "Members", members: [Member], isShortened: Bool) {
        self.title = title
        self.members = members
        self.isShortened = isShortened
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .modifier(
                    RoundFontModifier(size: 17, foregroundColor: UIComponentsAsset.textSecondary.swiftUIColor))
                .padding(.leading, 15)
            
            VStack(alignment: .leading, spacing: 0) {
                MembersTableButton(
                    systemImageName: "person.fill.badge.plus",
                    title: "Add member",
                    imageSize: 25
                ) {
                    print("Add members plz")
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
                        title: "\(membersForTest.count) members",
                        imageSize: 20
                    ) {
                        print("Show all members")
                    }
                }
            }
            .padding(.vertical, 5)
            .background(UIComponentsAsset.backgroundSecondary.swiftUIColor)
            .cornerRadius(24)
        }
    }
}

#Preview {
    VStack {
        MembersTable(title: "Members", members: Array(membersForTest.prefix(4)), isShortened: true)
        
        MembersTable(title: "Members", members: membersForTest, isShortened: false)
    }
    .padding()
}
