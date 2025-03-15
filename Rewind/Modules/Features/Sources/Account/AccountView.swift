import SwiftUI
import UIComponents

public struct AccountView: View {
    // TODO: Take viewModel from Assemmbly/Builder/Container
    @StateObject private var appIconsViewModel = AppIconsViewModel()
    @State private var isBlurredAvatarPresented = false

    public init() {}
    
    public var body: some View {
        VStack {
            if !isBlurredAvatarPresented {
                header
            }
            
            ZStack {
                Color.white.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 15) {
                        avatar
                            .onTapGesture {
                                isBlurredAvatarPresented.toggle()
                            }
                        
                        groupsTable
                        
                        activityTable
                        
                        generalTable
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("App Icons")
                                .foregroundColor(UIComponentsAsset.tableNameTextColor.swiftUIColor)
                                .font(.system(size: 17, weight: .black, design: .rounded))
                                .padding(.leading, 15)
                            
                            appIconsTable
                        }
                        
                        riskyTable
                    }
                    .padding(.horizontal, 16)
                }
                .scrollIndicators(.hidden)
                
                if isBlurredAvatarPresented {
                    BlurredAvatarView(
                        image: UIComponentsAsset.avatar.image,
                        isPresented: $isBlurredAvatarPresented
                    )
                }
            }
        }
    }
    
    var header: some View {
        RewindHeader {
            RewindButton(type: .leftChevron) {
                print(1)
            }
        } centerView: {
            HStack(spacing: 12) {
                Image(uiImage: UIComponentsAsset.avatar.image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
                    .cornerRadius(20)
                
                Text("flowykk")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(UIComponentsAsset.primaryColor.swiftUIColor)
            }
        } rightView: {
            RewindButton(type: .empty) {}
        }
    }
    
    var avatar: some View {
      AvatarView(image: UIComponentsAsset.avatar.image, text: "flowykk")
    }
    
    var appIconsTable: some View {
        ZStack {
            AppIconsGridView()
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
        }
        .background(UIComponentsAsset.tableBackgroundColor.swiftUIColor)
        .cornerRadius(23)
    }
    
    var groupsTable: some View {
        InformationTable(title: "Groups", data: AccountConstants.groups, isRisky: false)
    }
    
    var activityTable: some View {
        InformationTable(title: "Activity", data: AccountConstants.activities, isRisky: false)
    }
    
    var generalTable: some View {
        InformationTable(title: "General", data: AccountConstants.general, isRisky: false)
    }
    
    var riskyTable: some View {
        InformationTable(title: "Risky Zone", data: AccountConstants.risky, isRisky: true)
    }
}

#Preview {
    AccountView()
}
