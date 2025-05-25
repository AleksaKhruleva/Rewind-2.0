import SwiftUI
import UIComponents
import Domain

public struct GroupView: View {
    @State private var isBlurredAvatarPresented = false

    private let group: Domain.Group
    private let router: GroupRouter

    public init(group: Domain.Group, router: GroupRouter) {
        self.group = group
        self.router = router
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
        }
        .background(Color.background)
        .overlay {
            if isBlurredAvatarPresented {
                BlurredAvatarView(
                    isPresented: $isBlurredAvatarPresented,
                    image: .constant(UIComponentsAsset.groupAvatar.image)
                )
            }
        }
    }

    private var header: some View {
        RewindHeader {
            RewindButton(type: .gearshape) {
                router.navigateToGroupSettings()
            }
        } centerView: {
            HeaderBadgeView(
                image: group.image,
                text: group.name
            )
        } rightView: {
            RewindButton(type: .rightChevron) {
                router.dismiss()
            }
        }
    }

    private var avatar: some View {
        AvatarView(image: group.image, text: group.name)
    }

    private var membersTable: some View {
        MembersTable(
            members: group.members ?? [],
            isShortened: true,
            onAddMemberTap: {
                router.navigateToAddMember(groupName: group.name)
            },
            onMemberTap: { member in
                router.navigateToMemberDetails(member)
            },
            onShowAllMembersTap: {
                router.navigateToMembersList(group.members ?? [])
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
                        router.navigateToRewindsStand()
                    }

                MembersTableButton(
                    systemImageName: "forward.fill",
                    title: UIComponentsStrings.Group.Stand.rolls,
                    imageSize: 15) {
                        router.navigateToRollsStand()
                    }
            }
            .padding(.vertical, 5)
            .background(Color.backgroundSecondary)
            .cornerRadius(24)
        }
    }

    @ViewBuilder
    private var galleryPreview: some View {
        if let gallery = group.gallery {
            GalleryScrollPreview(images: gallery, onChevronTap: {
                router.navigateToGallery()
            })
        }
    }

    @ViewBuilder
    private var groupExistenceNote: some View {
        if let days = group.daysSinceCreation {
            RewindNoteTextView(text: UIComponentsStrings.Group.note(days))
                .padding(.vertical, 4)
        }
    }
}
