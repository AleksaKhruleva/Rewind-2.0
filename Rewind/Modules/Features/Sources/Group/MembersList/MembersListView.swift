import SwiftUI
import UIComponents
import Domain

public struct MembersListView: View {
    @State private var searchText = ""
    
    private let router: MembersListRouter
    
    // ochevidno vremenno
    private var filteredMembers: [Member] {
        if searchText.isEmpty {
            return membersForTest
        } else {
            return membersForTest.filter { member in
                member.name.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    public init(router: MembersListRouter) {
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
                router.dismiss()
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
                router.navigateToAddMember()
            },
            onMemberTap: { member in
                router.navigateToMemberDetails(member)
            }
        )
        .animation(.easeInOut(duration: 0.3), value: filteredMembers)
    }
}
