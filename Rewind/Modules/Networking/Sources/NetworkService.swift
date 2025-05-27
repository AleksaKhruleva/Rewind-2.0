// swiftlint:disable function_parameter_count file_length
import SwiftUI
import Moya
import Foundation
import Domain
import Base

public protocol NetworkServiceProtocol {
    func register(email: String) async throws -> RegisterResponse
    func verifyEmail(registrationID: String, verificationCode: String) async throws -> SuccessResponse
    func finishRegister(password: String, registrationID: String, username: String) async throws -> UserTokensResponse

    func login(email: String, password: String) async throws -> UserTokensResponse

    func logout(tokens: Tokens) async throws -> SuccessResponse
    func deleteUser(tokens: Tokens, email: String) async throws -> SuccessResponse

    func refresh(refreshToken: String) async throws -> UserAccessTokenResponse
    func user(tokens: Tokens) async throws -> UserResponse

    func updateUserName(tokens: Tokens, name: String) async throws -> SuccessResponse
    func updateUserAvatar(tokens: Tokens, avatar: UIImage) async throws -> SuccessResponse

    func passwordResetSet(tokens: Tokens, password: String) async throws -> SuccessResponse
    func passwordResetStart(tokens: Tokens) async throws -> SuccessResponse
    func passwordResetVerify(tokens: Tokens, verificationCode: String) async throws -> SuccessResponse

    func checkPassword(tokens: Tokens, password: String) async throws -> SuccessResponse
    func emailStartChange(tokens: Tokens, email: String) async throws -> SuccessResponse
    func emailVerifyChange(tokens: Tokens, verificationCode: String) async throws -> SuccessResponse

    func createGroup(tokens: Tokens, name: String) async throws -> GroupResponse
    func fetchGroups(tokens: Tokens) async throws -> [GroupResponse]
    func fetchFullGroupDetails(tokens: Tokens, id: Int) async throws -> GroupDetails
    func updateGroupName(tokens: Tokens, id: Int, name: String) async throws -> GroupResponse
    func createGroupInvitationCode(tokens: Tokens, id: Int) async throws -> GroupInvitationCodeResponse
    func addUserToGroup(tokens: Tokens, invitationCode: String) async throws -> GroupResponse
    func deleteMemberFromGroup(tokens: Tokens, groupID: Int, memberID: String) async throws -> SuccessResponse
    func deleteGroup(tokens: Tokens, id: Int) async throws -> SuccessResponse

    func getMedias(tokens: Tokens, groupId: Int) async throws -> MediasResponse
    func getRandomMedias(tokens: Tokens, groupId: Int) async throws -> MediasResponse
    func addMedia(
        tokens: Tokens,
        groupId: Int,
        mediaType: String,
        mediaFile: UIImage,
        latitude: Double?,
        longitude: Double?,
        musicId: String?,
        offset: Double?,
        duration: Double?,
        tags: [String]
    ) async throws -> MediaResponse
    func deleteMedia(tokens: Tokens, groupId: Int, memoryId: Int) async throws -> SuccessResponse
    func addTag(tokens: Tokens, groupId: Int, memoryId: Int, tag: String) async throws -> TagResponse
    func deleteTag(tokens: Tokens, groupId: Int, memoryId: Int, tag: String) async throws -> TagResponse
    func likeMedia(tokens: Tokens, memoryId: Int) async throws -> SuccessResponse
    func unlikeMedia(tokens: Tokens, memoryId: Int) async throws -> SuccessResponse
    func getMediaTags(tokens: Tokens, memoryId: Int) async throws -> TagsResponse
}

public final class NetworkService: NetworkServiceProtocol {
    private let provider = NetworkProvider<APIService>()

    public init() {}

    public func register(email: String) async throws -> RegisterResponse {
        try await provider.request(
            .register(
                email: email
            ),
            type: RegisterResponse.self
        )
    }

    public func verifyEmail(registrationID: String, verificationCode: String) async throws -> SuccessResponse {
        try await provider.request(
            .verifyEmail(
                registrationID: registrationID,
                verificationCode: verificationCode
            ),
            type: SuccessResponse.self
        )
    }

    public func finishRegister(
        password: String,
        registrationID: String,
        username: String
    ) async throws -> UserTokensResponse {
        try await provider.request(
            .finishRegister(
                password: password,
                registrationID: registrationID,
                username: username
            ),
            type: UserTokensResponse.self
        )
    }

    public func login(email: String, password: String) async throws -> UserTokensResponse {
        try await provider.request(
            .login(
                email: email,
                password: password
            ),
            type: UserTokensResponse.self
        )
    }

    public func logout(tokens: Tokens) async throws -> SuccessResponse {
        try await provider.request(
            .logout(
                accessToken: tokens.accessToken,
                refreshToken: tokens.refreshToken
            ),
            type: SuccessResponse.self
        )
    }

    public func deleteUser(tokens: Tokens, email: String) async throws -> SuccessResponse {
        try await retryOnUnauthorized(refreshToken: tokens.refreshToken) { [unowned self] newToken in
            try await self.provider.request(
                .deleteUser(
                    accessToken: newToken ?? tokens.accessToken,
                    email: email
                ),
                type: SuccessResponse.self
            )
        }
    }

    public func refresh(refreshToken: String) async throws -> UserAccessTokenResponse {
        try await provider.request(
            .refresh(
                refreshToken: refreshToken
            ),
            type: UserAccessTokenResponse.self
        )
    }

    public func user(tokens: Tokens) async throws -> UserResponse {
        try await retryOnUnauthorized(refreshToken: tokens.refreshToken) { [unowned self] newToken in
            try await self.provider.request(
                .user(
                    accessToken: newToken ?? tokens.accessToken
                ),
                type: UserResponse.self
            )
        }
    }

    public func updateUserName(tokens: Tokens, name: String) async throws -> SuccessResponse {
        try await retryOnUnauthorized(refreshToken: tokens.refreshToken) { [unowned self] newToken in
            try await self.provider.request(
                .updateUserName(
                    accessToken: newToken ?? tokens.accessToken,
                    name: name
                ),
                type: SuccessResponse.self
            )
        }
    }

    public func updateUserAvatar(tokens: Tokens, avatar: UIImage) async throws -> SuccessResponse {
        try await retryOnUnauthorized(refreshToken: tokens.refreshToken) { [unowned self] newToken in
            try await self.provider.request(
                .updateUserAvatar(
                    accessToken: newToken ?? tokens.accessToken,
                    avatar: avatar
                ),
                type: SuccessResponse.self
            )
        }
    }

    public func passwordResetSet(tokens: Tokens, password: String) async throws -> SuccessResponse {
        try await retryOnUnauthorized(refreshToken: tokens.refreshToken) { [unowned self] _ in
            try await self.provider.request(
                .passwordResetSet(
                    accessToken: tokens.accessToken,
                    password: password
                ),
                type: SuccessResponse.self
            )
        }
    }

    public func passwordResetStart(tokens: Tokens) async throws -> SuccessResponse {
        try await retryOnUnauthorized(refreshToken: tokens.refreshToken) { [unowned self] _ in
            try await self.provider.request(
                .passwordResetStart(
                    accessToken: tokens.accessToken
                ),
                type: SuccessResponse.self
            )
        }
    }

    public func passwordResetVerify(tokens: Tokens, verificationCode: String) async throws -> SuccessResponse {
        try await retryOnUnauthorized(refreshToken: tokens.refreshToken) { [unowned self] _ in
            try await self.provider.request(
                .passwordResetVerify(
                    accessToken: tokens.accessToken,
                    verificationCode: verificationCode
                ),
                type: SuccessResponse.self
            )
        }
    }

    public func checkPassword(tokens: Tokens, password: String) async throws -> SuccessResponse {
        try await retryOnUnauthorized(refreshToken: tokens.refreshToken) { [unowned self] _ in
            try await self.provider.request(
                .checkPassword(
                    accessToken: tokens.accessToken,
                    password: password
                ),
                type: SuccessResponse.self
            )
        }
    }

    public func emailStartChange(tokens: Tokens, email: String) async throws -> SuccessResponse {
        try await retryOnUnauthorized(refreshToken: tokens.refreshToken) { [unowned self] _ in
            try await self.provider.request(
                .emailStartChange(
                    accessToken: tokens.accessToken,
                    email: email
                ),
                type: SuccessResponse.self
            )
        }
    }

    public func emailVerifyChange(tokens: Tokens, verificationCode: String) async throws -> SuccessResponse {
        try await retryOnUnauthorized(refreshToken: tokens.refreshToken) { [unowned self] _ in
            try await self.provider.request(
                .emailVerifyChange(
                    accessToken: tokens.accessToken,
                    verificationCode: verificationCode
                ),
                type: SuccessResponse.self
            )
        }
    }

    public func getMedias(tokens: Tokens, groupId: Int) async throws -> MediasResponse {
        try await retryOnUnauthorized(refreshToken: tokens.refreshToken) { [unowned self] _ in
            try await self.provider.request(
                .getMedias(
                    accessToken: tokens.accessToken,
                    groupId: groupId
                ),
                type: MediasResponse.self
            )
        }
    }

    public func getRandomMedias(tokens: Tokens, groupId: Int) async throws -> MediasResponse {
        try await retryOnUnauthorized(refreshToken: tokens.refreshToken) { [unowned self] _ in
            try await self.provider.request(
                .getRandomMedias(
                    accessToken: tokens.accessToken,
                    groupId: groupId
                ),
                type: MediasResponse.self
            )
        }
    }

    public func addMedia(
        tokens: Tokens,
        groupId: Int,
        mediaType: String,
        mediaFile: UIImage,
        latitude: Double? = nil,
        longitude: Double? = nil,
        musicId: String? = nil,
        offset: Double? = nil,
        duration: Double? = nil,
        tags: [String] = []
    ) async throws -> MediaResponse {
        try await retryOnUnauthorized(refreshToken: tokens.refreshToken) { [unowned self] _ in
            try await self.provider.request(
                .addMedia(
                    accessToken: tokens.accessToken,
                    groupId: String(groupId),
                    mediaType: mediaType,
                    mediaFile: mediaFile,
                    latitude: latitude,
                    longitude: longitude,
                    musicId: musicId,
                    offset: offset,
                    duration: duration,
                    tags: tags
                ),
                type: MediaResponse.self
            )
        }
    }

    public func deleteMedia(tokens: Tokens, groupId: Int, memoryId: Int) async throws -> SuccessResponse {
        try await retryOnUnauthorized(refreshToken: tokens.refreshToken) { [unowned self] _ in
            try await self.provider.request(
                .deleteMedia(
                    accessToken: tokens.accessToken,
                    groupId: groupId,
                    memoryId: memoryId
                ),
                type: SuccessResponse.self
            )
        }
    }

    public func addTag(tokens: Tokens, groupId: Int, memoryId: Int, tag: String) async throws -> TagResponse {
        try await retryOnUnauthorized(refreshToken: tokens.refreshToken) { [unowned self] _ in
            try await self.provider.request(
                .addTag(
                    accessToken: tokens.accessToken,
                    groupId: groupId,
                    memoryId: memoryId,
                    tag: tag
                ),
                type: TagResponse.self
            )
        }
    }

    public func deleteTag(tokens: Tokens, groupId: Int, memoryId: Int, tag: String) async throws -> TagResponse {
        try await retryOnUnauthorized(refreshToken: tokens.refreshToken) { [unowned self] _ in
            try await self.provider.request(
                .deleteTag(
                    accessToken: tokens.accessToken,
                    groupId: groupId,
                    memoryId: memoryId,
                    tag: tag
                ),
                type: TagResponse.self
            )
        }
    }

    public func likeMedia(tokens: Tokens, memoryId: Int) async throws -> SuccessResponse {
        try await retryOnUnauthorized(refreshToken: tokens.refreshToken) { [unowned self] _ in
            try await self.provider.request(
                .likeMedia(
                    accessToken: tokens.accessToken,
                    memoryId: memoryId
                ),
                type: SuccessResponse.self
            )
        }
    }

    public func unlikeMedia(tokens: Tokens, memoryId: Int) async throws -> SuccessResponse {
        try await retryOnUnauthorized(refreshToken: tokens.refreshToken) { [unowned self] _ in
            try await self.provider.request(
                .unlikeMedia(
                    accessToken: tokens.accessToken,
                    memoryId: memoryId
                ),
                type: SuccessResponse.self
            )
        }
    }

    public func getMediaTags(tokens: Tokens, memoryId: Int) async throws -> TagsResponse {
        try await retryOnUnauthorized(refreshToken: tokens.refreshToken) { [unowned self] _ in
            try await self.provider.request(
                .getMediaTags(
                    accessToken: tokens.accessToken,
                    memoryId: memoryId
                ),
                type: TagsResponse.self
            )
        }
    }

    public func createGroup(tokens: Tokens, name: String) async throws -> GroupResponse {
        try await retryOnUnauthorized(refreshToken: tokens.refreshToken) { [unowned self] _ in
            try await provider.request(
                .createGroup(accessToken: tokens.accessToken, name: name),
                type: GroupResponse.self
            )
        }
    }

    public func fetchGroups(tokens: Tokens, ) async throws -> [GroupResponse] {
        try await retryOnUnauthorized(refreshToken: tokens.refreshToken) { [unowned self] _ in
            let response = try await provider.request(
                .fetchGroups(accessToken: tokens.accessToken),
                type: GroupsListResponse.self
            )
            return response.groups
        }
    }

    public func fetchFullGroupDetails(tokens: Tokens, id: Int) async throws -> GroupDetails {
        async let group = fetchGroup(tokens: tokens, id: id)
        async let members = fetchGroupMembers(tokens: tokens, id: id)
        return GroupDetails(group: try await group, members: try await members)
    }

    public func updateGroupName(tokens: Tokens, id: Int, name: String) async throws -> GroupResponse {
        try await retryOnUnauthorized(refreshToken: tokens.refreshToken) { [unowned self] _ in
            try await provider
                .request(
                    .updateGroupName(
                        accessToken: tokens.accessToken,
                        id: id,
                        name: name
                    ),
                    type: GroupResponse.self
                )
        }
    }

    public func createGroupInvitationCode(tokens: Tokens, id: Int) async throws -> GroupInvitationCodeResponse {
        try await retryOnUnauthorized(refreshToken: tokens.refreshToken) { [unowned self] _ in
            try await provider
                .request(
                    .createGroupInvitation(
                        accessToken: tokens.accessToken,
                        id: id
                    ),
                    type: GroupInvitationCodeResponse.self
                )
        }
    }

    public func addUserToGroup(tokens: Tokens, invitationCode: String) async throws -> GroupResponse {
        try await retryOnUnauthorized(refreshToken: tokens.refreshToken) { [unowned self] _ in
            let response = try await provider
                .request(
                    .addUserToGroup(
                        accessToken: tokens.accessToken,
                        invitationCode: invitationCode
                    ),
                    type: AddUserToGroupResponse.self
                )
            return response.group
        }
    }

    public func deleteMemberFromGroup(tokens: Tokens, groupID: Int, memberID: String) async throws -> SuccessResponse {
        try await retryOnUnauthorized(refreshToken: tokens.refreshToken) { [unowned self] _ in
            try await provider
                .request(
                    .deleteMemberFromGroup(
                        accessToken: tokens.accessToken,
                        groupID: groupID,
                        memberID: memberID
                    ),
                    type: SuccessResponse.self
                )
        }
    }

    public func deleteGroup(tokens: Tokens, id: Int) async throws -> SuccessResponse {
        try await retryOnUnauthorized(refreshToken: tokens.refreshToken) { [unowned self] _ in
            try await provider
                .request(
                    .deleteGroup(accessToken: tokens.accessToken, id: id),
                    type: SuccessResponse.self
                )
        }
    }
}

extension NetworkService {
    private func retryOnUnauthorized<T>(
        refreshToken: String,
        _ perform: @escaping (String?) async throws -> T
    ) async throws -> T {
        do {
            return try await perform(nil)
        } catch let httpError as HTTPError where httpError == .unauthorized {
            let newToken = try await refresh(refreshToken: refreshToken).accessToken
            KeychainService.shared.save(newToken, for: .accessToken)

            return try await perform(newToken)
        }
    }

    private func fetchGroup(tokens: Tokens, id: Int) async throws -> GroupResponse {
        try await retryOnUnauthorized(refreshToken: tokens.refreshToken) { [unowned self] _ in
            try await provider.request(
                .fetchGroup(accessToken: tokens.accessToken, id: id),
                type: GroupResponse.self
            )
        }
    }

    private func fetchGroupMembers(tokens: Tokens, id: Int) async throws -> [GroupMemberResponse] {
        try await retryOnUnauthorized(refreshToken: tokens.refreshToken) { [unowned self] _ in
            let response = try await provider.request(
                .fetchGroupMembers(accessToken: tokens.accessToken, id: id),
                type: GroupMembersListResponse.self
            )
            return response.members
        }
    }
}
// swiftlint:enable function_parameter_count file_length
