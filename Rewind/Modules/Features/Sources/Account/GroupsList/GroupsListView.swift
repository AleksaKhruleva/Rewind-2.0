import SwiftUI
import UIComponents
import Domain

public struct GroupsListView: View {
    @State private var searchText = ""

    private let router: GroupsListRouter

    // ochevidno vremenno
    private var filteredGroups: [Domain.Group] {
        if searchText.isEmpty {
            return []
        } else {
            return [].filter { group in
                group.name.lowercased().contains(searchText.lowercased())
            }
        }
    }

    public init(router: GroupsListRouter) {
        self.router = router
    }

    public var body: some View {
        VStack {
            header

            ScrollView {
                VStack(spacing: 15) {
                    searchField

                    groupsTable
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
        }
        .background(Color.background)
    }

    private var header: some View {
        RewindHeader {
            RewindButton(type: .leftChevron) {
                router.dismiss()
            }
        } centerView: {
            Text(UIComponentsStrings.Groups.title)
                .modifier(RoundFontModifier(size: 17, weight: .bold))
                .foregroundColor(.textPrimary)
        } rightView: {
            RewindButton(type: .leftChevron).hidden()
        }
    }

    private var searchField: some View {
        RewindSearchField(text: $searchText, placeholder: UIComponentsStrings.Groups.Search.placeholder)
    }

    private var groupsTable: some View {
        GroupsTable(
            title: UIComponentsStrings.Rewind.Groups.count(filteredGroups.count),
            groups: filteredGroups,
            onAddGroupTap: { print("Add group here") },
            onGroupTap: { group in print("Select group \(group.name) here") }
        )
        .animation(.easeInOut(duration: 0.3), value: filteredGroups)
    }
}

#Preview {
    GroupsListView(router: GroupsListRouter(appRouter: AppRouter()))
}
