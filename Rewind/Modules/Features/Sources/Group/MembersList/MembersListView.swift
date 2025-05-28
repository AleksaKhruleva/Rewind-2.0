import SwiftUI
import UIComponents
import Domain

public struct MembersListView: View {
    @State private var viewModel: MembersListViewModel
    @State private var searchText = ""

    private var filteredMembers: [Member] {
        if searchText.isEmpty {
            return viewModel.groupMembers
        } else {
            let searchQuery = searchText
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .localizedLowercase

            return viewModel.groupMembers.filter { member in
                member.name.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }

    public init(group: Domain.Group, router: MembersListRouter) {
        viewModel = MembersListViewModel(group: group, router: router)
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
        .overlay {
            if viewModel.isLoading {
                ZStack {
                    Color.background.ignoresSafeArea()

                    ProgressView(viewModel.progressMessage)
                        .modifier(RoundFontModifier(size: 15))
                }
            }
        }
        .task {
            await viewModel.dispatch(.loadGroupImage)
        }
    }

    private var header: some View {
        RewindHeader(centerView: {
            HeaderBadgeView(
                image: viewModel.groupImage,
                text: viewModel.group.name
            )
        }, rightView: {
            RewindButton(type: .rightChevron) {
                hideKeyboard()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewModel.router.dismiss()
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
                Task {
                    await viewModel.dispatch(.createInvitation)
                }
            },
            onMemberTap: { member in
                viewModel.router.navigateToMemberDetails(member)
            },
            onDeleteMember: { member in
                Task {
                    await viewModel.dispatch(.deleteMember(member))
                }
            }
        )
        .animation(.easeInOut(duration: 0.3), value: filteredMembers)
    }
}
