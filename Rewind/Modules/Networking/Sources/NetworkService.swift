import Moya
import Foundation
import Domain

public protocol NetworkServiceProtocol {
    func register(email: String) async throws -> RegisterResponse
    func verifyEmail(registrationID: String, verificationCode: String) async throws -> SuccessResponse
    func finishRegister(password: String, registrationID: String, username: String) async throws -> UserTokensResponse
    func login(email: String, password: String) async throws -> UserTokensResponse
    func logout(refreshToken: String) async throws -> SuccessResponse
    func deleteUser(email: String) async throws -> SuccessResponse
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
    
    public func finishRegister(password: String, registrationID: String, username: String) async throws -> UserTokensResponse {
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
}
