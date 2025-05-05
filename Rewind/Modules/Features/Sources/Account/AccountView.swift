import SwiftUI
import UIComponents
import Base

public struct AccountView: View {
    @State private var appIconsViewModel: AppIconsViewModel
    @State private var viewModel: AccountViewModel
    
    @State private var isBlurredAvatarPresented = false
    @State private var signOutAlertPresented = false
    @State private var deleteAccountAlertPresented = false
    
    @Environment(\.dismiss)
    private var dismiss
    @Environment(\.showToast)
    private var showToast
    
    public init(router: AccountRouter) {
        appIconsViewModel = AppIconsViewModel()
        viewModel = AccountViewModel(router: router)
    }
    
    public var body: some View {
        ZStack {
            Color.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                
                ScrollView {
                    VStack(spacing: 15) {
                        avatar.onTapGesture {
                                withAnimation(.spring(response: 0.2)) {
                                    isBlurredAvatarPresented = true
                                }
                            }
                        
                        groupsTable
                        
                        activityTable
                        
                        generalTable
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text(UIComponentsStrings.Account.appicons)
                                .foregroundColor(.textSecondary)
                                .modifier(RoundFontModifier(size: AccountConstants.defaultFontSize, weight: .black))
                                .padding(.leading, 15)
                            
                            appIconsTable
                        }
                        
                        riskyTable
                        
                        RewindNoteTextView(text: UIComponentsStrings.Account.Note.you(100))
                            .padding(.vertical, 4)
                    }
                    .padding(.horizontal, 16)
                }
                .scrollIndicators(.hidden)
            }
            .onAppear {
                viewModel.set(showToast: showToast)
                Task { await viewModel.dispatch(.fetchUser) }
            }
            .overlay {
                if isBlurredAvatarPresented {
                    BlurredAvatarView(
                        image: UIComponentsAsset.avatar.image,
                        isPresented: $isBlurredAvatarPresented
                    )
                }
            }
            .alert(UIComponentsStrings.Account.SignOut.Alert.title, isPresented: $signOutAlertPresented) {
                VStack {
                    Button(UIComponentsStrings.Buttons.continue, role: .cancel) {
                        Task { await viewModel.dispatch(.signOut) }
                    }
                    Button(UIComponentsStrings.Buttons.cancel, role: .destructive) { }
                }
            }
            .alert(UIComponentsStrings.Account.DeleteAccount.Alert.title, isPresented: $deleteAccountAlertPresented) {
                VStack {
                    Button(UIComponentsStrings.Buttons.continue, role: .cancel) {
                        Task { await viewModel.dispatch(.deleteAccount) }
                    }
                    Button(UIComponentsStrings.Buttons.cancel, role: .destructive) { }
                }
            }
        }
    }
    
    var header: some View {
        RewindHeader {
            RewindButton(type: .leftChevron) { dismiss() }
        } centerView: {
            HeaderBadgeView(
                image: UIComponentsAsset.avatar.image,
                text: viewModel.user.name
            )
        } rightView: {
            RewindButton(type: .empty).hidden()
        }
    }
    
    var avatar: some View {
      AvatarView(image: UIComponentsAsset.avatar.image, text: viewModel.user.name)
    }
    
    var appIconsTable: some View {
        ZStack {
            AppIconsGridView()
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
        }
        .background(Color.backgroundSecondary)
        .cornerRadius(23)
    }
    
    var groupsTable: some View {
        InformationTable(title: UIComponentsStrings.Account.groups, data: AccountConstants.groups, isRisky: false)
    }
    
    var activityTable: some View {
        InformationTable(title: UIComponentsStrings.Account.activity, data: AccountConstants.activities, isRisky: false)
    }
    
    var generalTable: some View {
        InformationTable(title: UIComponentsStrings.Account.general, data: AccountConstants.general, isRisky: false)
    }
    
    var riskyTable: some View {
        InformationTable(
            title: UIComponentsStrings.Account.risky,
            data: [
                ("rectangle.portrait.and.arrow.right.fill", UIComponentsStrings.Account.Risky.signout, {
                    signOutAlertPresented = true
                }),
                ("trash.fill", UIComponentsStrings.Account.Risky.delete, {
                    deleteAccountAlertPresented = true
                })
            ],
            isRisky: true
        )
    }
}

#Preview {
    let router = AppRouter()
    AccountView(router: .init(appRouter: router))
}
