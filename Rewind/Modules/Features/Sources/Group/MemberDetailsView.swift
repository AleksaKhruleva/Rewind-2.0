import SwiftUI
import UIComponents
import Domain

// let nilAction: (() -> Void)? = nil // temporary
let groupsData = [("person.2.fill", UIComponentsStrings.Account.Groups.count(8), nilAccessibility, nilAction)]
let activitiesData = [
    ("photo.fill.on.rectangle.fill", UIComponentsStrings.Account.Activity.rewinds(245), nilAccessibility, nilAction),
    ("person.fill", UIComponentsStrings.Account.Activity.people(15), nilAccessibility, nil),
    ("forward.fill", UIComponentsStrings.Account.Activity.rolls(92), nilAccessibility, nil)
]

public struct MemberDetailsView: View {
    private let member: Member

    private weak var router: AppRouter?

    public init(member: Member, router: AppRouter) {
        self.member = member
        self.router = router
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
    }

    private var header: some View {
        RewindHeader(centerView: {
            HeaderBadgeView(image: member.image, text: member.name)
        }, rightView: {
            RewindButton(type: .rightChevron) {
                router?.pop()
            }
        })
    }

    private var avatar: some View {
        AvatarView(image: member.image, text: member.name)
    }

    private var groupsTable: some View {
        InformationTable(title: UIComponentsStrings.Account.groups, data: groupsData, isRisky: false)
    }

    private var activityTable: some View {
        InformationTable(title: UIComponentsStrings.Account.activity, data: activitiesData, isRisky: false)
    }

    private var userExistenceNote: some View {
        RewindNoteTextView(text: UIComponentsStrings.Account.Note.stranger(member.name, 100))
            .padding(.vertical, 4)
    }
}
