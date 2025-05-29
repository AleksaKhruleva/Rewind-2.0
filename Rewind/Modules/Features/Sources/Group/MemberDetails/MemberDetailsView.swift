import SwiftUI
import UIComponents
import Domain
import Base

public struct MemberDetailsView: View {
    @State private var viewModel: MemberDetailsViewModel
    @State private var image: UIImage = DomainAsset.userPlacholder.image

    private weak var router: AppRouter?

    @Environment(\.showToast)
    private var showToast

    public init(member: Member, router: AppRouter) {
        self.router = router
        viewModel = MemberDetailsViewModel(member: member)
    }

    public var body: some View {
        VStack {
            header

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 15) {
                    avatar

                    groupsTable

                    activityTable

                    userExistenceNote
                }
                .padding(.horizontal, 16)
            }
        }
        .background(Color.background)
        .task {
            await viewModel.dispatch(.fetchUser) {
                showToast(UIComponentsStrings.Toast.error)
            }
            image = await ImageProvider.loadOrGetImage(for: viewModel.member.imageURL, .user)
        }
    }

    private var header: some View {
        RewindHeader {
            RewindButton(type: .rightChevron).hidden()
        } centerView: {
            HeaderBadgeView(image: image, text: viewModel.member.name)
        } rightView: {
            RewindButton(type: .rightChevron) {
                router?.pop()
            }
        }
    }

    private var avatar: some View {
        AvatarView(image: image, text: viewModel.member.name)
    }

    private var groupsTable: some View {
        InformationTable(title: UIComponentsStrings.Account.groups, data: [
            ("person.2.fill", UIComponentsStrings.Account.Groups.count(8), nilAccessibility, nilAction)
        ], isRisky: false)
    }

    @ViewBuilder
    private var activityTable: some View {
        if let activity = viewModel.activity {
            InformationTable(
                title: UIComponentsStrings.Account.activity,
                data: [
                    (
                        "photo.fill.on.rectangle.fill",
                        UIComponentsStrings.Rewind.countLld(activity.memoriesAddedCount),
                        nil,
                        nil
                    ),
                    (
                        "person.fill",
                        UIComponentsStrings.People.countLld(activity.invitedMembersCount),
                        nil,
                        nil
                    ),
                    (
                        "forward.fill",
                        UIComponentsStrings.Rolls.countLld(activity.memoriesViewedCount),
                        nil,
                        nil
                    )
                ],
                isRisky: false
            )
        }
    }

    @ViewBuilder
    private var userExistenceNote: some View {
        if let activity = viewModel.activity {
            RewindNoteTextView(text: UIComponentsStrings.Account.Note.you(
                UIComponentsStrings.Days.countLld(activity.daysSince)
            )).padding(.vertical, 4)
        }
    }
}
