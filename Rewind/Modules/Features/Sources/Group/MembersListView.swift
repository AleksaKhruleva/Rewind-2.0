import SwiftUI
import UIComponents

// докручу этот экран позже, сейчас он меня бесит уже 😔
public struct MembersListView: View {
    @State private var searchText = ""
    
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
    
    public init() {}
    
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
        RewindHeader {
            RewindButton(type: .empty)
        } centerView: {
            HeaderBadgeView(image: UIComponentsAsset.groupAvatar.image, text: UIComponentsStrings.Members.title("Friends'"))
        } rightView: {
            RewindButton(type: .rightChevron) {
                // TODO: go back
            }
        }
    }
    
    private var searchField: some View {
        RewindSearchField(text: $searchText, placeholder: UIComponentsStrings.Group.Members.Search.placeholder)
    }
    
    private var membersTable: some View {
        MembersTable(
            title: UIComponentsStrings.Group.Members.count(filteredMembers.count),
            members: filteredMembers,
            isShortened: false
        )
    }
}

#Preview {
    MembersListView()
}
