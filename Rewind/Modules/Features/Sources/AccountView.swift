import SwiftUI
import UIComponents

public struct AccountView: View {
    let groups = [
        ("person.2.fill", "8 group", true)
    ]
    
    let activities = [
        ("photo.fill.on.rectangle.fill", "124 added Rewinds", false),
        ("person.fill", "3 invited people", false),
        ("backward.fill", "245 rewind rolls", false)
    ]
    
    let general = [
        ("photo.fill", "Change image", true),
        ("pencil", "Change name", true),
        ("key.fill", "Change password", true),
        ("envelope.fill", "Change email", true),
        ("gift.fill", "Set a widget", true),
        ("questionmark.circle.fill", "Get help", true),
        ("link.circle.fill", "Share with friends", true)
    ]
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 15) {
                    avatar
                    
                    groupsTable
                    
                    activityTable
                    
                    generalTable
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("App Icons")
                            .foregroundColor(Color("tableNameTextColor"))
                            .font(.custom("Nunito-Black", size: 17))
                            .padding(.leading, 15)
                        
                        appIconsTable
                    }
                    
                    riskyTable
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
        }
    }
    
    var avatar: some View {
        VStack {
            Image("avatar")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 130, height: 130)
                .cornerRadius(65)
            
            Text("flowykk")
                .foregroundColor(Color("tableTextColor"))
                .font(.custom("Nunito-Black", size: 20))
        }
    }
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    public var appIconsTable: some View {
        ZStack {
            LazyVGrid(columns: columns, spacing: 20) {
//                AppIcon(imageName: "rewindLight", task: "5 days", locked: false)
//                AppIcon(imageName: "rewindPink", task: "5 days", locked: true)
//                AppIcon(imageName: "rewindGradient", task: "20 rewinds", locked: true)
//                AppIcon(imageName: "rewindSakura", task: "2 groups", locked: true)
//                AppIcon(imageName: "rewindLazer", task: "5 invites", locked: true)
//                AppIcon(imageName: "rewindForest", task: "100 rolls", locked: true)
//                AppIcon(imageName: "rewindSea", task: "5 days", locked: true)
            }
            .padding(.top, 12)
            .padding(.bottom, 16)
            .padding(.horizontal, 8)
        }
        .background(Color("tableBackgroundColor"))
        .cornerRadius(23)
    }
    
    public var groupsTable: some View {
        InformationTable(title: "Groups", data: groups, isRisky: false)
    }
    
    public var activityTable: some View {
        InformationTable(title: "Activity", data: activities, isRisky: false)
    }
    
    public var generalTable: some View {
        InformationTable(title: "General", data: general, isRisky: false)
    }
    
    public var riskyTable: some View {
        InformationTable(title: "Risky Zone", data: [
            ("rectangle.portrait.and.arrow.right.fill", "Sign out", true),
            ("trash.fill", "Delete account", true)
        ], isRisky: true)
    }
}

#Preview {
    AccountView()
}
