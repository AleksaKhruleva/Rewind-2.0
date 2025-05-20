import SwiftUI
import UIComponents

let images = [
    UIComponentsAsset.media1.image,
    UIComponentsAsset.media2.image,
    UIComponentsAsset.media3.image,
    UIComponentsAsset.media4.image,
    UIComponentsAsset.media6.image,
    UIComponentsAsset.media7.image,
    UIComponentsAsset.media8.image,
    UIComponentsAsset.media9.image,
    UIComponentsAsset.media10.image,
]

public struct GroupView: View {
    @State private var isBlurredAvatarPresented = false
    
    private let router: GroupRouter
    
    public init(router: GroupRouter) {
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
                    image: UIComponentsAsset.groupAvatar.image,
                    isPresented: $isBlurredAvatarPresented
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
                image: UIComponentsAsset.groupAvatar.image,
                text: "Friends"
            )
        } rightView: {
            RewindButton(type: .rightChevron) {
                router.dismiss()
            }
        }
    }
    
    private var avatar: some View {
        AvatarView(image: UIComponentsAsset.groupAvatar.image, text: "Friends")
    }
    
    private var membersTable: some View {
        MembersTable(
            members: Array(membersForTest.prefix(4)),
            isShortened: true,
            onAddMemberTap: {
                router.navigateToAddMember()
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
    
    private var galleryPreview: some View {
        GalleryScrollPreview(images: images, onChevronTap: {
            router.navigateToGallery()
        })
    }
    
    private var groupExistenceNote: some View {
        RewindNoteTextView(text: UIComponentsStrings.Group.note(100))
            .padding(.vertical, 4)
    }
}
