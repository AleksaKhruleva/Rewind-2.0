import SwiftUI
import Moya
import Foundation
import Base
import Domain

enum APIService {
    case register(email: String)
    case verifyEmail(registrationID: String, verificationCode: String)
    case finishRegister(password: String, registrationID: String, username: String)

    case login(email: String, password: String)

    case logout(accessToken: String, refreshToken: String)
    case deleteUser(accessToken: String, email: String)

    case refresh(refreshToken: String)
    case user(accessToken: String)

    case updateUserName(accessToken: String, name: String)
    case updateUserAvatar(accessToken: String, avatar: UIImage)

    case passwordResetSet(accessToken: String, password: String)
    case passwordResetStart(accessToken: String)
    case passwordResetVerify(accessToken: String, verificationCode: String)

    case checkPassword(accessToken: String, password: String)
    case emailStartChange(accessToken: String, email: String)
    case emailVerifyChange(accessToken: String, verificationCode: String)

    case createGroup(accessToken: String, name: String)
    case fetchGroups(accessToken: String)
    case fetchGroup(accessToken: String, id: Int)
    case fetchGroupMembers(accessToken: String, id: Int)
    case updateGroupName(accessToken: String, id: Int, name: String)
    case createGroupInvitation(accessToken: String, id: Int)
    case deleteGroup(accessToken: String, id: Int)
    case addUserToGroup(accessToken: String, invitationCode: String)
    case deleteMemberFromGroup(accessToken: String, groupID: Int, memberID: String)

    case getMedias(accessToken: String, groupId: Int)
    case getRandomMedias(accessToken: String, groupId: Int)
    case addMedia(accessToken: String, groupId: String, mediaType: String, mediaFile: UIImage)
    case deleteMedia(accessToken: String, groupId: Int, memoryId: Int)
    case addTag(accessToken: String, groupId: Int, memoryId: Int, tag: String)
    case deleteTag(accessToken: String, groupId: Int, memoryId: Int, tag: String)
    case likeMedia(accessToken: String, memoryId: Int)
    case unlikeMedia(accessToken: String, memoryId: Int)
    case getMediaTags(accessToken: String, memoryId: Int)
}

extension APIService: TargetType {
    var baseURL: URL {
        if CommandLine.arguments.contains("-useLocalhost") {
            return URL(string: "http://localhost:8080")!
        }
        return URL(string: "https://rewindapp.ru/api")!
    }

    var path: String {
        switch self {
        case .register:
            return "/auth/register"
        case .verifyEmail:
            return "/auth/verify-email"
        case .finishRegister:
            return "/auth/finish-register"
        case .login:
            return "/auth/login"
        case .logout:
            return "/users/logout"
        case .deleteUser:
            return "/users/delete-user"
        case .refresh:
            return "/auth/refresh"
        case let .user(accessToken):
            let id = JWTDecoder().getUserId(from: accessToken) ?? "undefined"
            return "users/\(id)"
        case .updateUserName:
            return "users/username"
        case .updateUserAvatar:
            return "users/avatar"
        case .passwordResetSet:
            return "users/password/reset/set"
        case .passwordResetStart:
            return "users/password/reset/start"
        case .passwordResetVerify:
            return "users/password/reset/verify"
        case .checkPassword:
            return "users/check-password"
        case .emailStartChange:
            return "users/email/start-change"
        case .emailVerifyChange:
            return "users/email/verify-change"
        case .createGroup:
            return "/groups"
        case .fetchGroups:
            return "/users/groups"
        case let .fetchGroup(_, id):
            return "/groups/\(id)"
        case let .fetchGroupMembers(_, id):
            return "/groups/\(id)/members"
        case let .updateGroupName(_, id, _):
            return "/groups/\(id)"
        case let .createGroupInvitation(_, id):
            return "/groups/\(id)/invitations"
        case let .deleteGroup(_, id):
            return "/groups/\(id)"
        case let .addUserToGroup(_, invitationCode):
            return "/invitations/\(invitationCode)/accept"
        case let .getMedias(_, groupId):
            return "groups/\(groupId)/memories"
        case let .getRandomMedias(_, groupId):
            let groupId = 1
            return "groups/\(groupId)/memories/filter"
        case let .addMedia(_, groupId, _, _):
            return "groups/\(groupId)/memories"
        case let .deleteMedia(_, groupId, memoryId):
            return "groups/\(groupId)/memories/\(memoryId)"
        case let .addTag(_, groupId, memoryId, tag):
            return "groups/\(groupId)/memories/\(memoryId)/tags/\(tag)"
        case let .deleteTag(_, groupId, memoryId, tag):
            return "groups/\(groupId)/memories/\(memoryId)/tags/\(tag)"
        case let .likeMedia(_, memoryId):
            return "memories/\(memoryId)/favourite"
        case let .unlikeMedia(_, memoryId):
            return "memories/\(memoryId)/favourite"
        case let .getMediaTags(_, memoryId):
            return "memories/\(memoryId)/tags"
        case let .deleteMemberFromGroup(_, groupID, memberID):
            return "/groups/\(groupID)/members/\(memberID)"
        }
    }

    var method: Moya.Method {
        switch self {
        case .user,
                .fetchGroups,
                .fetchGroup,
                .fetchGroupMembers,
                .getMedias,
                .getRandomMedias,
                .getMediaTags:
            return .get
        case .register,
                .verifyEmail,
                .finishRegister,
                .login,
                .logout,
                .refresh,
                .passwordResetStart,
                .passwordResetVerify,
                .checkPassword,
                .emailStartChange,
                .createGroup,
                .createGroupInvitation,
                .addTag,
                .likeMedia,
                .addMedia,
                .addUserToGroup:
            return .post
        case .updateUserName,
                .updateUserAvatar,
                .passwordResetSet,
                .emailVerifyChange:
            return .patch
        case .deleteUser,
                .deleteGroup,
                .unlikeMedia,
                .deleteTag,
                .deleteMedia,
                .deleteMemberFromGroup:
            return .delete
        case .updateGroupName:
            return .put
        }
    }

    var task: Moya.Task {
        switch self {
        case let .register(email):
            return jsonRequest(["email": email])
        case let .verifyEmail(registrationID, verificationCode):
            return jsonRequest(["registration_id": registrationID, "verification_code": verificationCode])
        case let .finishRegister(password, registrationID, username):
            let parameters = [
                "password": password,
                "registration_id": registrationID,
                "username": username
            ]
            return jsonRequest(parameters)
        case let .login(email, password):
            let parameters = ["email": email, "password": password]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case let .logout(_, refreshToken):
            let parameters = ["refresh_token": refreshToken]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case let .deleteUser(_, email):
            let parameters = ["email": email]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case let .refresh(refreshToken):
            let parameters = ["refresh_token": refreshToken]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case .user:
            return .requestPlain
        case let .updateUserName(_, name):
            let parameters = ["new_username": name]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case let .updateUserAvatar(_, avatar):
            guard let imageData = avatar.jpegData(compressionQuality: 1) else {
                return .requestPlain
            }

            let formData = MultipartFormData(
                provider: .data(imageData),
                name: "image",
                fileName: "image.jpg",
                mimeType: "image/jpeg"
            )
            return .uploadMultipart([formData])
        case let .passwordResetSet(_, password):
            let parameters = ["new_password": password]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case .passwordResetStart:
            return .requestPlain
        case let .passwordResetVerify(_, verificationCode):
            let parameters = ["verification_code": verificationCode]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case let .checkPassword(_, password):
            let parameters = ["password": password]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case let .emailStartChange(_, email):
            let parameters = ["new_email": email]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case let .emailVerifyChange(_, verificationCode):
            let parameters = ["verification_code": verificationCode]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case let .createGroup(_, name):
            return jsonRequest(["image": "aboba", "name": name])
        case let .updateGroupName(_, _, name):
            guard let nameData = name.data(using: .utf8) else {
                return .requestPlain
            }
            let formData = MultipartFormData(
                provider: .data(nameData),
                name: "name"
            )
            return .uploadMultipart([formData])
        case .createGroupInvitation,
                .addUserToGroup,
                .deleteMemberFromGroup:
            return jsonRequest([:])
        case .fetchGroups,
                .fetchGroup,
                .fetchGroupMembers,
                .deleteGroup:
                return .requestPlain
        case .getMedias:
            return .requestPlain
        case .getRandomMedias:
            return .requestPlain
        case let .addMedia(_, groupId, mediaType, mediaFile):
            guard let imageData = mediaFile.jpegData(compressionQuality: 1),
                  let groupIdData = groupId.data(using: .utf8),
                  let mediaTypeData = mediaType.data(using: .utf8) else {
                return .requestPlain
            }

            return .uploadMultipart([
                MultipartFormData(
                    provider: .data(imageData),
                    name: "mediaFile",
                    fileName: "mediaFile.jpg",
                    mimeType: "mediaFile/jpeg"
                ),
                MultipartFormData(
                    provider: .data(groupIdData),
                    name: "groupId"
                ),
                MultipartFormData(
                    provider: .data(mediaTypeData),
                    name: "mediaType"
                )
            ])
        case .deleteMedia:
            return .requestPlain
        case .addTag:
            return .requestPlain
        case .deleteTag:
            return .requestPlain
        case .likeMedia:
            return .requestPlain
        case .unlikeMedia:
            return .requestPlain
        case .getMediaTags:
            return .requestPlain
        }
    }

    var headers: [String: String]? {
        switch self {
        case let .logout(accessToken, _),
            let .deleteUser(accessToken, _),
            let .user(accessToken),
            let .updateUserName(accessToken, _),
            let .updateUserAvatar(accessToken, _),
            let .passwordResetSet(accessToken, _),
            let .passwordResetStart(accessToken),
            let .passwordResetVerify(accessToken, _),
            let .checkPassword(accessToken, _),
            let .emailStartChange(accessToken, _),
            let .emailVerifyChange(accessToken, _),
            let .createGroup(accessToken, _),
            let .fetchGroups(accessToken),
            let .fetchGroup(accessToken, _),
            let .fetchGroupMembers(accessToken, _),
            let .updateGroupName(accessToken, _, _),
            let .deleteGroup(accessToken, _),
            let .createGroupInvitation(accessToken, _),
            let .getMedias(accessToken, _),
            let .getRandomMedias(accessToken, _),
            let .addMedia(accessToken, _, _, _),
            let .deleteMedia(accessToken, _, _),
            let .addTag(accessToken, _, _, _),
            let .deleteTag(accessToken, _, _, _),
            let .likeMedia(accessToken, _),
            let .unlikeMedia(accessToken, _),
            let .getMediaTags(accessToken, _),
            let .addUserToGroup(accessToken, _),
            let .deleteMemberFromGroup(accessToken, _, _):
            return [
                "Authorization": "Bearer \(accessToken)",
                "Content-Type": "application/json"
            ]
        default:
            return ["Content-Type": "application/json"]
        }
    }

    private func jsonRequest(_ parameters: [String: Any]) -> Moya.Task {
        .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
    }
}
