import Moya
import Foundation
import Base

enum APIService {
    case register(email: String)
    case verifyEmail(registrationID: String, verificationCode: String)
    case finishRegister(password: String, registrationID: String, username: String)
    case login(email: String, password: String)
    case logout(refreshToken: String)
    case deleteUser(email: String)
    case refresh(refreshToken: String)
    case user(accessToken: String)
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
            return "/auth/logout"
        case .deleteUser:
            return "/auth/delete-user"
        case .refresh:
            return "/auth/refresh"
        case let .user(accessToken):
            let id = JWTDecoderService().getUserId(from: accessToken) ?? "undefined"
            return "users/\(id)"
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
            .refresh:
            return .post
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
        case let .logout(refreshToken):
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
        }
    }
    
    var headers: [String : String]? {
        switch self {
        case let .user(accessToken):
            return [
                "Authorization": "Bearer \(accessToken)",
                "Content-Type": "application/json"
            ]
        default:
            return ["Content-Type": "application/json"]
        }
    }
}
