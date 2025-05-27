import SwiftUI
import UIComponents
import Domain

let imageSize: CGFloat = 90

struct GroupSelectionView: View {
    @State private var viewModel: GroupSelectionViewModel
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    private let onGroupSelected: ((Domain.Group) -> Void)?

    private var filteredGroups: [Domain.Group] {
        if searchText.isEmpty {
            return viewModel.groups
        } else {
            return viewModel.groups.filter { group in
                group.name.lowercased().contains(searchText.lowercased())
            }
        }
    }

    init(user: User, groups: [Domain.Group], router: RewindRouter, onGroupSelected: ((Domain.Group) -> Void)?) {
        self.onGroupSelected = onGroupSelected
        viewModel = GroupSelectionViewModel(user: user, groups: groups, router: router)
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
                isLoading: $viewModel.isLoading,
                error: $viewModel.groupNameError,
                message: "Creating new group..."
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
            Text(UIComponentsStrings.Group.Select.count(viewModel.groups.count))
                .modifier(RoundFontModifier(size: 17, foregroundColor: .textSecondary))
                .padding(.leading, 16)

            ZStack(alignment: .trailing) {
                RoundedRectangle(cornerRadius: 35, style: .continuous)
                    .fill(Color.background)

                GroupsScrollView(
                    selectedGroupID: viewModel.currentGroup?.id,
                    groups: filteredGroups,
                    imageSize: imageSize,
                    onGroupSelected: { newGroup in
                        viewModel.currentGroup = CurrentGroupInfo(
                            id: newGroup.id,
                            name: newGroup.name,
                            imageData: newGroup.imageData
                        )
                        onGroupSelected?(newGroup)
                        dismiss()
                    }
                )
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
                    title: UIComponentsStrings.Group.Select.count(viewModel.groups.count),
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
