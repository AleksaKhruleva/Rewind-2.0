import Moya
import Foundation
import Domain
import Base

public protocol NetworkServiceProtocol {
    func register(email: String) async throws -> RegisterResponse
    func verifyEmail(registrationID: String, verificationCode: String) async throws -> SuccessResponse
    func finishRegister(password: String, registrationID: String, username: String) async throws -> UserTokensResponse
    func login(email: String, password: String) async throws -> UserTokensResponse
    func logout(refreshToken: String) async throws -> SuccessResponse
    func deleteUser(email: String) async throws -> SuccessResponse
    func refresh(refreshToken: String) async throws -> UserAccessTokenResponse
    func user(accessToken: String, refreshToken: String) async throws -> UserResponse
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

    public func logout(refreshToken: String) async throws -> SuccessResponse {
        try await provider.request(
            .logout(
                refreshToken: refreshToken
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

    public func user(accessToken: String, refreshToken: String) async throws -> UserResponse {
        try await retryOnUnauthorized(refreshToken: refreshToken) { [unowned self] newToken in
            try await self.provider.request(
                .user(
                    accessToken: newToken ?? accessToken
                ),
                type: UserResponse.self
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
