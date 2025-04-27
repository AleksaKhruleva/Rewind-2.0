import SwiftUI
import UIComponents

// vremenno
let memberName = "Matthew"
let memberAvatar = UIComponentsAsset.matthewMcConaughey.image

let groupsData = [("person.2.fill", "8 group", false)]
let activitiesData = [
    ("photo.fill.on.rectangle.fill", "124 added Rewinds", false),
    ("person.fill", "3 invited people", false),
    ("forward.fill", "245 rewind rolls", false)
]

public struct MemberDetailsView: View {
    public init() {}
    
    public var body: some View {
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
        InformationTable(title: "Groups", data: groupsData, isRisky: false)
    }
    
    private var activityTable: some View {
        InformationTable(title: "Activity", data: activitiesData, isRisky: false)
    }
    
    private var userExistenceNote: some View {
        RewindNoteTextView(text: "✨  \(memberName) is already 100 days with Rewind!")
            .padding(.vertical, 4)
    }
}

#Preview {
    MemberDetailsView()
}
