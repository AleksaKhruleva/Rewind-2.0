import SwiftUI
import UIComponents
import Domain

public struct MembersListView: View {
    @State private var searchText = ""

    private let router: MembersListRouter
    private let members: [Member]

    private var filteredMembers: [Member] {
        if searchText.isEmpty {
            return members
        } else {
            let searchQuery = searchText
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .localizedLowercase

            return members.filter { member in
                member.name.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }

    public init(members: [Member], router: MembersListRouter) {
        self.members = members
        self.router = router
    }

    public var body: some View {
        VStack {
            header

            ScrollView {
                VStack(spacing: 15) {
                    searchField

                    membersTable
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color.background)
    }

    private var header: some View {
        RewindHeader(centerView: {
            HeaderBadgeView(
                image: UIComponentsAsset.groupAvatar.image,
                text: "Friends"
            )
        }, rightView: {
            RewindButton(type: .rightChevron) {
                hideKeyboard()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    router.dismiss()
                }
            }
        })
    }

    private var searchField: some View {
        RewindSearchField(text: $searchText, placeholder: UIComponentsStrings.Group.Members.Search.placeholder)
    }

    private var membersTable: some View {
        MembersTable(
            title: UIComponentsStrings.Group.Members.count(filteredMembers.count),
            members: filteredMembers,
            isShortened: false,
            onAddMemberTap: {
                router.navigateToAddMember(groupName: "Friends")
            },
            onMemberTap: { member in
                router.navigateToMemberDetails(member)
            }
        )
        .animation(.easeInOut(duration: 0.3), value: filteredMembers)
    }
}
