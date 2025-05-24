import SwiftUI
import UIComponents
import Base

import Domain

public struct AccountView: View {
    @State private var appIconsViewModel: AppIconsViewModel
    @State private var viewModel: AccountViewModel
    
    @State private var imageEditingDialogShown = false
    @State private var photoPickerShown = false
    @State private var blurredAvatarShown = false
    @State private var signOutAlertShown = false
    @State private var deleteAccountAlertShown = false
    
    @State private var genericSheetItem: GenericInputSheetItem?
    
    @Environment(\.showToast)
    private var showToast
    
    public init(router: AccountRouter) {
        appIconsViewModel = AppIconsViewModel()
        viewModel = AccountViewModel(router: router)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            header
            
            ScrollView {
                VStack(spacing: 15) {
                    avatar.onTapGesture {
                        withAnimation(.spring(response: 0.2)) {
                            guard viewModel.user.imageData != nil else {
                                photoPickerShown = true
                                return
                            }
                            blurredAvatarShown = true
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
        .background(Color.background)
        .confirmationDialog(
            UIComponentsStrings.Account.Edit.Image.Dialog.title,
            isPresented: $imageEditingDialogShown,
            titleVisibility: .visible
        ) {
            Button(UIComponentsStrings.Account.Edit.Image.Dialog.setNew) {
                photoPickerShown = true
            }
            Button(UIComponentsStrings.Account.Edit.Image.Dialog.delete, role: .destructive) {
                Task {
                    await viewModel.dispatch(.deleteImage)
                }
            }
        }
        .customImagePicker(show: $photoPickerShown, croppedImage: Binding {
            return viewModel.user.image
        } set: { newImage in
            Task { await viewModel.dispatch(.setImage(newImage)) }
        }) {
            showToast(UIComponentsStrings.Account.Edit.Image.Set.success)
        }
        .sheet(item: $genericSheetItem) { item in
            switch item {
            case .name:
                AccountNameEditingFlow() {
                    Task { await viewModel.dispatch(.fetchUser) }
                    showToast(UIComponentsStrings.Account.Edit.Name.success)
                }
            case .password:
                AccountPasswordEditingFlow() {
                    showToast(UIComponentsStrings.Account.Edit.Password.success)
                }
            case .email:
                AccountEmailEditingFlow() {
                    showToast(UIComponentsStrings.Account.Edit.Email.success)
                }
            default: EmptyView()
            }
        }
        .onAppear {
            viewModel.set(showToast: showToast)
            Task { await viewModel.dispatch(.fetchUser) }
        }
        .overlay {
            if blurredAvatarShown {
                BlurredAvatarView(
                    isPresented: $blurredAvatarShown,
                    image: viewModel.imageBinding
                )
            }
        }
        .alert(UIComponentsStrings.Account.SignOut.Alert.title, isPresented: $signOutAlertShown) {
            VStack {
                Button(UIComponentsStrings.Buttons.continue, role: .cancel) {
                    Task { await viewModel.dispatch(.signOut) }
                }
                Button(UIComponentsStrings.Buttons.cancel, role: .destructive) { }
            }
        }
        .alert(UIComponentsStrings.Account.DeleteAccount.Alert.title, isPresented: $deleteAccountAlertShown) {
            VStack {
                Button(UIComponentsStrings.Buttons.continue, role: .cancel) {
                    Task { await viewModel.dispatch(.deleteAccount) }
                }
                Button(UIComponentsStrings.Buttons.cancel, role: .destructive) { }
            }
        }
    }
    
    var header: some View {
        RewindHeader {
            RewindButton(type: .leftChevron) { viewModel.router.dismiss() }
        } centerView: {
            HeaderBadgeView(
                image: viewModel.user.image,
                text: viewModel.user.name
            )
        } rightView: {
            RewindButton(type: .leftChevron).hidden()
        }
    }
    
    var avatar: some View {
        AvatarView(image: viewModel.user.image, text: viewModel.user.name)
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
        InformationTable(
            title: UIComponentsStrings.Account.general,
            data: [
                ("photo.fill", UIComponentsStrings.Account.General.image, {
                    imageEditingDialogShown = true
                }),
                ("pencil", UIComponentsStrings.Account.General.name, {
                    genericSheetItem = .name
                }),
                ("key.fill", UIComponentsStrings.Account.General.password, {
                    genericSheetItem = .password
                }),
                ("envelope.fill", UIComponentsStrings.Account.General.email, {
                    genericSheetItem = .email
                }),
                ("gift.fill", UIComponentsStrings.Account.General.widget, {}),
                ("questionmark.circle.fill", UIComponentsStrings.Account.General.help, {}),
                ("globe", UIComponentsStrings.Account.General.git, {
                    UIApplication.shared.open(URL(string: "https://github.com/AleksaKhruleva/Rewind-2.0")!)
                })
            ],
            isRisky: false
        )
    }
    
    var riskyTable: some View {
        InformationTable(
            title: UIComponentsStrings.Account.risky,
            data: [
                ("rectangle.portrait.and.arrow.right.fill", UIComponentsStrings.Account.Risky.signout, {
                    signOutAlertShown = true
                }),
                ("trash.fill", UIComponentsStrings.Account.Risky.delete, {
                    deleteAccountAlertShown = true
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
