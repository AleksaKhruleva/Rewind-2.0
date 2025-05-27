import SwiftUI
import UIComponents
import Domain

public struct GroupView: View {
    @State private var viewModel: GroupViewModel
    @State private var isBlurredAvatarPresented = false
    @Environment(\.showToast) var showToast

    public init(group: Domain.Group, router: GroupRouter) {
        viewModel = GroupViewModel(group: group, router: router)
    }

    public var body: some View {
        VStack {
            header

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 15) {
                    avatar
                        .onTapGesture {
                            withAnimation {
                                isBlurredAvatarPresented.toggle()
                            }
                        }

                    membersTable

                    activityTable

                    galleryPreview

                    groupExistenceNote
                }
                .padding(.horizontal, 16)
            }
            .refreshable {
                await viewModel.dispatch(.refreshGroupData)
            }
        }
        .background(Color.background)
        .overlay {
            if isBlurredAvatarPresented {
                BlurredAvatarView(
                    isPresented: $isBlurredAvatarPresented,
                    image: .constant(viewModel.group.image)
                )
            }
        }
        .overlay {
            if viewModel.isRefreshing {
                ZStack {
                    Color.background.ignoresSafeArea()

                    ProgressView(viewModel.refreshMessage)
                        .modifier(RoundFontModifier(size: 15))
                }
            }
        }
        .onChange(of: viewModel.toastMessage) {
            if let message = viewModel.toastMessage {
                showToast(message)
                viewModel.toastMessage = nil
            }
        }
    }

    private var header: some View {
        RewindHeader {
            RewindButton(type: .gearshape) {
                viewModel.router.navigateToGroupSettings(viewModel.group)
            }
        } centerView: {
            HeaderBadgeView(
                image: viewModel.group.image,
                text: viewModel.group.name
            )
        } rightView: {
            RewindButton(type: .rightChevron) {
                viewModel.router.dismiss()
            }
        }
    }

    private var avatar: some View {
        AvatarView(image: viewModel.group.image, text: viewModel.group.name)
    }

    private var membersTable: some View {
        MembersTable(
            members: viewModel.shortGroupMembers,
            isShortened: true,
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
            },
            onShowAllMembersTap: {
                viewModel.router.navigateToMembersList(viewModel.group)
            }
        )
    }

    // думаю, стоит либо сделать отдельно SectionTable, либо чуть "обобщить" InformationTable,
    // чтобы код в activityTable тоже можно было в эту таблицу обернуть, короче позже переделаю
    private var activityTable: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(UIComponentsStrings.Group.activity)
                .modifier(RoundFontModifier(size: 17, foregroundColor: .textSecondary))
                .padding(.leading, 15)
            VStack(alignment: .leading, spacing: 5) {
                MembersTableButton(
                    systemImageName: "photo.on.rectangle",
                    title: UIComponentsStrings.Group.Stand.rewinds,
                    imageSize: 20) {
                        viewModel.router.navigateToRewindsStand()
                    }

                MembersTableButton(
                    systemImageName: "forward.fill",
                    title: UIComponentsStrings.Group.Stand.rolls,
                    imageSize: 15) {
                        viewModel.router.navigateToRollsStand()
                    }
            }
            .padding(.vertical, 5)
            .background(Color.backgroundSecondary)
            .cornerRadius(24)
        }
    }

    @ViewBuilder
    private var galleryPreview: some View {
        if let gallery = viewModel.group.gallery {
            GalleryScrollPreview(images: gallery, onChevronTap: {
                viewModel.router.navigateToGallery()
            })
        }
    }

    @ViewBuilder
    private var groupExistenceNote: some View {
        if let days = viewModel.group.daysSinceCreation {
            RewindNoteTextView(text: UIComponentsStrings.Group.note(days))
                .padding(.vertical, 4)
        }
    }
}
