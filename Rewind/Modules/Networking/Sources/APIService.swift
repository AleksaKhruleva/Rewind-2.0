import Moya
import Foundation
import Base

enum APIService {
    case register(email: String)
    case verifyEmail(registrationID: String, verificationCode: String)
    case finishRegister(password: String, registrationID: String, username: String)
    
    case login(email: String, password: String)
    
    case logout(accessToken: String, refreshToken: String)
    case deleteUser(email: String)
    
    case refresh(refreshToken: String)
    case user(accessToken: String)
    
    case updateName(accessToken: String, name: String)
    
    case passwordResetSet(accessToken: String, password: String)
    case passwordResetStart(accessToken: String)
    case passwordResetVerify(accessToken: String, verificationCode: String)
    
    case checkPassword(accessToken: String, password: String)
    case emailStartChange(accessToken: String, email: String)
    case emailVerifyChange(accessToken: String, verificationCode: String)
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
            return "/auth/delete-user"
        case .refresh:
            return "/auth/refresh"
        case let .user(accessToken):
            let id = JWTDecoderService().getUserId(from: accessToken) ?? "undefined"
            return "users/\(id)"
        case .updateName:
            return "users/username"
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
        }
    }

    var method: Moya.Method {
        switch self {
        case .user:
            return .get
        case .register,
                .verifyEmail,
                .finishRegister,
                .login,
                .logout,
                .deleteUser,
                .refresh,
                .passwordResetStart,
                .passwordResetVerify,
                .checkPassword,
                .emailStartChange:
            return .post
        case .updateName,
                .passwordResetSet,
                .emailVerifyChange:
            return .patch
        }
    }

    var task: Moya.Task {
        switch self {
        case let .register(email):
            let parameters = ["email": email]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case let .verifyEmail(registrationID, verificationCode):
            let parameters = ["registration_id": registrationID, "verification_code": verificationCode]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case let .finishRegister(password, registrationID, username):
            let parameters = [
                "password": password,
                "registration_id": registrationID,
                "username": username
            ]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case let .login(email, password):
            let parameters = ["email": email, "password": password]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case let .logout(_, refreshToken):
            let parameters = ["refresh_token": refreshToken]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case let .deleteUser(email):
            let parameters = ["email": email]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case let .refresh(refreshToken):
            let parameters = ["refresh_token": refreshToken]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        case .user:
            return .requestPlain
        case let .updateName(_, name):
            let parameters = ["new_username": name]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
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
        }
    }

    var headers: [String: String]? {
        switch self {
        case let .logout(accessToken, _),
            let .user(accessToken),
            let .updateName(accessToken, _),
            let .passwordResetSet(accessToken, _),
            let .passwordResetStart(accessToken),
            let .passwordResetVerify(accessToken, _),
            let .checkPassword(accessToken, _),
            let .emailStartChange(accessToken, _),
            let .emailVerifyChange(accessToken, _):
            return [
                "Authorization": "Bearer \(accessToken)",
                "Content-Type": "application/json"
            ]
        default:
            return ["Content-Type": "application/json"]
        }
    }
}
