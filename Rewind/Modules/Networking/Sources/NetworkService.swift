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
    func deleteUser(email: String) async throws -> SuccessResponse

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

    public func deleteUser(email: String) async throws -> SuccessResponse {
        try await provider.request(
            .deleteUser(
                email: email
            ),
            type: SuccessResponse.self
        )
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
}
