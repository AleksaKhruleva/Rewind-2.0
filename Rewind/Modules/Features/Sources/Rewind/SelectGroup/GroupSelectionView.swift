import SwiftUI
import UIComponents

let imageSize: CGFloat = 90

struct GroupSelectionView: View {
    @State private var viewModel: GroupSelectionViewModel
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss
    
    private var filteredGroups: [RewindGroup] {
        if searchText.isEmpty {
            return groupsForTest
        } else {
            return groupsForTest.filter { group in
                group.name.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    private let router: RewindRouter
    
    init(router: RewindRouter) {
        self.router = router
        viewModel = GroupSelectionViewModel(router: router)
    }
    
    var body: some View {
        ZStack {
            Color.backgroundSecondary.ignoresSafeArea()

            VStack(spacing: 20) {
                Text(UIComponentsStrings.Group.Select.title)
                    .modifier(RoundFontModifier(size: 21))

                searchField

                groupsScroll

                suggestionsTable
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $viewModel.isGroupCreationViewPresented) {
            GroupNameInputView(
                isPresented: $viewModel.isGroupCreationViewPresented,
                isLoading: $viewModel.isLoading
            ) { name in
                Task {
                    await viewModel.dispatch(.createGroup(name))
                }
            }
        }
        .onChange(of: viewModel.shouldDismissSelf) { _, shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
    }

    private var searchField: some View {
        RewindSearchField(
            text: $searchText,
            placeholder: UIComponentsStrings.Group.Select.Search.placeholder,
            backgroundColor: Color.background
        )
    }

    private var groupsScroll: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(UIComponentsStrings.Group.Select.count(images.count))
                .modifier(RoundFontModifier(size: 17, foregroundColor: .textSecondary))
                .padding(.leading, 16)

            ZStack(alignment: .trailing) {
                RoundedRectangle(cornerRadius: 35, style: .continuous)
                    .fill(Color.background)

                GroupsScrollView(groups: filteredGroups, imageSize: imageSize)
                    .frame(height: imageSize + 20)
                    .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
                    .padding(.horizontal, 15)
            }
            .frame(height: imageSize + 40)
        }
    }

    // временно
    private var suggestionsTable: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(UIComponentsStrings.Group.Select.suggestions)
                .modifier(
                    RoundFontModifier(
                        size: AccountConstants.defaultFontSize,
                        foregroundColor: .textSecondary
                    )
                )
                .padding(.leading, 15)

            VStack(alignment: .leading, spacing: 0) {
                suggestionRow(
                    icon: "plus",
                    title: UIComponentsStrings.Group.Select.add,
                    action: {
                        viewModel.isGroupCreationViewPresented = true
                    }
                )
                suggestionRow(
                    icon: "person.2.fill",
                    title: UIComponentsStrings.Group.Select.count(images.count),
                    action: {
                        // aboba
                    }
                )
            }
            .background(Color.background)
            .cornerRadius(20)
        }
    }

    // временно
    private func suggestionRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .modifier(RoundFontModifier(size: 20))
                .frame(width: 34, height: 34)

            Text(title)
                .modifier(RoundFontModifier(size: AccountConstants.defaultFontSize))

            Spacer()

            Image(systemName: "chevron.right")
                .modifier(RoundFontModifier(size: 17))
                .frame(width: 30, height: 30)
        }
        .foregroundColor(.textPrimary)
        .contentShape(Rectangle())
        .frame(height: 50)
        .padding(.horizontal)
        .onTapGesture {
            action()
        }
    }
}
