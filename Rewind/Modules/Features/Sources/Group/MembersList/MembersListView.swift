import SwiftUI
import UIComponents
import Domain

public struct MembersListView: View {
    @State private var searchText = ""

    private let router: MembersListRouter
    private let group: Domain.Group

    private var groupMembers: [Member] {
        group.members ?? []
    }

    private var filteredMembers: [Member] {
        if searchText.isEmpty {
            return groupMembers
        } else {
            let searchQuery = searchText
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .localizedLowercase

            return groupMembers.filter { member in
                member.name.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }

    public init(
        group: Domain.Group,
        router: MembersListRouter
    ) {
        self.group = group
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
                image: group.image,
                text: group.name
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
                router.navigateToAddMember(groupName: group.name, link: "") // TODO: request link later
            },
            onMemberTap: { member in
                router.navigateToMemberDetails(member)
            }
        )
        .animation(.easeInOut(duration: 0.3), value: filteredMembers)
    }
}
