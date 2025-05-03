import SwiftUI
import UIComponents

// vremenno
let memberName = "Matthew"
let memberAvatar = UIComponentsAsset.matthewMcConaughey.image

let nilAction: (() -> Void)? = nil // temporary
let groupsData = [("person.2.fill", UIComponentsStrings.Account.Groups.count(8), nilAction)]
let activitiesData = [
    ("photo.fill.on.rectangle.fill", UIComponentsStrings.Account.Activity.rewinds(245), nilAction),
    ("person.fill", UIComponentsStrings.Account.Activity.people(15), nil),
    ("forward.fill", UIComponentsStrings.Account.Activity.rolls(92), nil)
]

public struct MemberDetailsView: View {
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            VStack {
                header
                
                ScrollView {
                    VStack(spacing: 15) {
                        avatar
                        
                        groupsTable
                        
                        activityTable
                        
                        userExistenceNote
                    }
                    .padding(.horizontal, 16)
                }
                .scrollIndicators(.hidden)
            }
        }
    }
    
    private var header: some View {
        RewindHeader {
            RewindButton(type: .empty) {}
        } centerView: {
            HeaderBadgeView(
                image: memberAvatar,
                text: memberName
            )
        } rightView: {
            RewindButton(type: .rightChevron) {
                print(1)
            }
        }
    }
    
    private var avatar: some View {
        AvatarView(image: memberAvatar, text: memberName)
    }
    
    private var groupsTable: some View {
        InformationTable(title: UIComponentsStrings.Account.groups, data: groupsData, isRisky: false)
    }
    
    private var activityTable: some View {
        InformationTable(title: UIComponentsStrings.Account.activity, data: activitiesData, isRisky: false)
    }
    
    private var userExistenceNote: some View {
        RewindNoteTextView(text: UIComponentsStrings.Account.Note.stranger(memberName, 100))
            .padding(.vertical, 4)
    }
}

#Preview {
    MemberDetailsView()
}
