import SwiftUI
import UIComponents

// vremenno
let memberName = "Matthew"
let memberAvatar = UIComponentsAsset.matthewMcConaughey.image

let nilAction: (() -> Void)? = nil // temporary
let groupsData = [("person.2.fill", "8 group", nilAction)]
let activitiesData = [
    ("photo.fill.on.rectangle.fill", "124 added Rewinds", nilAction),
    ("person.fill", "3 invited people", nil),
    ("forward.fill", "245 rewind rolls", nil)
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
