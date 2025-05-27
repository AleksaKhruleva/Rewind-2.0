import SwiftUI
import UIComponents
import Domain
import Base

public struct GroupSettingsView: View {
    @State private var viewModel: GroupSettingsViewModel
    @State private var deleteGroupAlertShown = false
    @State private var leaveGroupAlertShown = false
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
    }

    private var header: some View {
        RewindHeader {
            RewindButton(type: .rightChevron).hidden()
        } centerView: {
            HeaderBadgeView(
                image: viewModel.group.image,
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
            image: viewModel.group.image,
            text: viewModel.group.name
        )
    }

    private var generalTable: some View {
        let generalData = [
            ("photo.fill", UIComponentsStrings.Group.Settings.General.name, nilAccessibility, {
                viewModel.needNameInputView = true
            }),
            ("pencil", UIComponentsStrings.Group.Settings.General.image, nilAccessibility, {})
        ]
        return InformationTable(title: UIComponentsStrings.Group.Settings.general, data: generalData, isRisky: false)
    }

    private var riskyTable: some View {
        Group {
            if let tokens = Tokens(),
               let userID = JWTDecoder().getUserId(from: tokens.accessToken),
               let ownerID = viewModel.group.ownerID {
                InformationTable(
                    title: UIComponentsStrings.Group.Settings.risky,
                    data: String(ownerID) == userID ? [
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
