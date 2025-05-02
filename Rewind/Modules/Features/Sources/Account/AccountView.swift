import SwiftUI
import UIComponents

public struct AccountView: View {
    @State private var appIconsViewModel: AppIconsViewModel
    @State private var viewModel: AccountViewModel
    @State private var isBlurredAvatarPresented = false

    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.showToast)
    private var showToast
    
    public init(router: AccountRouter) {
        appIconsViewModel = AppIconsViewModel()
        viewModel = AccountViewModel(router: router)
    }
    
    public var body: some View {
        VStack {
            header
            
            ScrollView {
                VStack(spacing: 15) {
                    avatar
                        .onTapGesture {
                            withAnimation(.spring(response: 0.2)) {
                                isBlurredAvatarPresented = true
                            }
                        }
                    
                    groupsTable
                    
                    activityTable
                    
                    generalTable
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("App Icons")
                            .foregroundColor(UIComponentsAsset.tableNameTextColor.swiftUIColor)
                            .modifier(RoundFontModifier(size: AccountConstants.defaultFontSize, weight: .black))
                            .padding(.leading, 15)
                        
                        appIconsTable
                    }
                    
                    riskyTable
                    
                    RewindNoteTextView(text: "✨  You are already 100 days with Rewind!")
                        .padding(.vertical, 4)
                }
                .padding(.horizontal, 16)
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            viewModel.set(showToast: showToast)
        }
        .overlay {
            if isBlurredAvatarPresented {
                BlurredAvatarView(
                    image: UIComponentsAsset.avatar.image,
                    isPresented: $isBlurredAvatarPresented
                )
            }
        }
    }
    
    var header: some View {
        RewindHeader {
            RewindButton(type: .leftChevron) { dismiss() }
        } centerView: {
            HeaderBadgeView(
                image: UIComponentsAsset.avatar.image,
                text: "flowykk"
            )
        } rightView: {
            RewindButton(type: .empty).hidden()
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
        InformationTable(
            title: "Risky Zone",
            data: [
                ("rectangle.portrait.and.arrow.right.fill", "Sign out", {
                    Task { await viewModel.dispatch(.signOut) }
                }),
                ("trash.fill", "Delete account", {})
            ],
            isRisky: true
        )
    }
}

#Preview {
    let router = AppRouter()
    AccountView(router: .init(appRouter: router))
}
