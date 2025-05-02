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
        ZStack {
            UIComponentsAsset.background.swiftUIColor.ignoresSafeArea()
            
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
        }
    }
    
    private var header: some View {
        RewindHeader {
            RewindButton(type: .empty)
        } centerView: {
            HeaderBadgeView(image: UIComponentsAsset.groupAvatar.image, text: "Friends' Members")
        } rightView: {
            RewindButton(type: .rightChevron) {
                // TODO: go back
            }
        }
    }
    
    private var searchField: some View {
        RewindSearchField(text: $searchText, placeholder: "Member's name")
    }
    
    private var membersTable: some View {
        MembersTable(
            title: "\(filteredMembers.count) \(filteredMembers.count > 1 ? "members" : "member")",
            members: filteredMembers,
            isShortened: false
        )
    }
}

#Preview {
    MembersListView()
}
