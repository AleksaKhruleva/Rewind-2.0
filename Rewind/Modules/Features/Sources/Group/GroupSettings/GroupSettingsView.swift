import SwiftUI
import UIComponents
import Domain
import Base

public struct GroupSettingsView: View {
    @State private var viewModel: GroupSettingsViewModel
    @State private var deleteGroupAlertShown = false
    @State private var leaveGroupAlertShown = false
    @State private var imageEditDialogShown = false
    @State private var photoPickerShown = false
    @Environment(\.showToast) private var showToast

    public init(group: Domain.Group, router: GroupSettingsRouter) {
        viewModel = GroupSettingsViewModel(group: group, router: router)
    }

    public var body: some View {
        VStack {
            header

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 15) {
                    avatar

                    generalTable

                    riskyTable
                }
                .padding(.horizontal, 16)
            }
        }
        .background(Color.background)
        .sheet(isPresented: $viewModel.needNameInputView) {
            GroupNameInputView(
                isPresented: $viewModel.needNameInputView,
                isLoading: $viewModel.isLoading,
                error: $viewModel.groupNameError,
                message: viewModel.progressMessage
            ) { newName in
                Task {
                    await viewModel.dispatch(.updateName(newName))
                }
            }
        }
        .onChange(of: viewModel.toastMessage) {
            if let message = viewModel.toastMessage {
                showToast(message)
                viewModel.toastMessage = nil
            }
        }
        .alert(
            "Are you sure you want to delete your group? You will not be able to undo this action.",
            isPresented: $deleteGroupAlertShown
        ) {
            VStack {
                Button(UIComponentsStrings.Buttons.cancel, role: .cancel) { }

                Button(
                    UIComponentsStrings.Buttons.continue,
                    role: .destructive
                ) {
                    Task { await viewModel.dispatch(.deleteGroup) }
                }
            }
        }
        .alert(
            "Are you sure you want to leave the group?",
            isPresented: $leaveGroupAlertShown,
            actions: {
                VStack {
                    Button(UIComponentsStrings.Buttons.cancel, role: .cancel) { }

                    Button(
                        UIComponentsStrings.Buttons.continue,
                        role: .destructive
                    ) {
                        Task { await viewModel.dispatch(.leaveGroup) }
                    }
                }
            }
        )
        .overlay {
            if viewModel.isLoading {
                ZStack {
                    Color.background.ignoresSafeArea()

                    ProgressView(viewModel.progressMessage)
                        .modifier(RoundFontModifier(size: 15))
                }
            }
        }
        .confirmationDialog(
            "What to do with the group image?",
            isPresented: $imageEditDialogShown,
            actions: {
                Button(UIComponentsStrings.Account.Edit.Image.Dialog.setNew) {
                    photoPickerShown = true
                }
                Button(UIComponentsStrings.Account.Edit.Image.Dialog.delete, role: .destructive) {
                    print("delete")
                }
            }
        )
        .customImagePicker(show: $photoPickerShown, croppedImage: Binding {
            return viewModel.groupImage
        } set: { newImage in
            Task { await viewModel.dispatch(.updateImage(newImage)) }
        })
        .task {
            await viewModel.dispatch(.loadGroupImage)
        }
    }

    private var header: some View {
        RewindHeader {
            RewindButton(type: .rightChevron).hidden()
        } centerView: {
            HeaderBadgeView(
                image: viewModel.groupImage,
                text: viewModel.group.name
            )
        } rightView: {
            RewindButton(type: .rightChevron) {
                viewModel.router.dismiss()
            }
        }
    }

    private var avatar: some View {
        AvatarView(
            image: viewModel.groupImage,
            text: viewModel.group.name
        )
    }

    private var generalTable: some View {
        let generalData = [
            ("pencil", UIComponentsStrings.Group.Settings.General.name, nilAccessibility, {
                viewModel.needNameInputView = true
            }),
            ("photo.fill", UIComponentsStrings.Group.Settings.General.image, nilAccessibility, {
                imageEditDialogShown = true
            })
        ]
        return InformationTable(
            title: UIComponentsStrings.Group.Settings.general,
            data: generalData,
            isRisky: false
        )
    }

    private var riskyTable: some View {
        Group {
            if let tokens = Tokens(), let userID = JWTDecoder().getUserId(from: tokens.accessToken) {
                InformationTable(
                    title: UIComponentsStrings.Group.Settings.risky,
                    data: String(viewModel.group.ownerID) == userID ? [
                        (
                            "rectangle.portrait.and.arrow.right.fill",
                            UIComponentsStrings.Group.Settings.Risky.leave, nil, {
                                leaveGroupAlertShown = true
                            }
                        ),
                        ("trash.fill", UIComponentsStrings.Group.Settings.Risky.delete, nil, {
                            deleteGroupAlertShown = true
                        })
                    ] : [
                        (
                            "rectangle.portrait.and.arrow.right.fill",
                            UIComponentsStrings.Group.Settings.Risky.leave, nil, {
                                leaveGroupAlertShown = true
                            }
                        )
                    ],
                    isRisky: true
                )
            } else {
                EmptyView()
            }
        }
    }
}
