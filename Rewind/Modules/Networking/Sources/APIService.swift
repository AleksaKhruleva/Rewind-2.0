import Moya
import Foundation

enum APIService {
    case register(email: String)
    case verifyEmail(registrationID: String, verificationCode: String)
    case finishRegister(password: String, registrationID: String, username: String)
    case login(email: String, password: String)
    case logout(refreshToken: String)
}

extension APIService: TargetType {
    var baseURL: URL {
        URL(string: "https://rewindapp.ru/api")!
    }
    
    var path: String {
        switch self {
        case .register:
            "/auth/register"
        case .verifyEmail:
            "/auth/verify-email"
        case .finishRegister:
            "/auth/finish-register"
        case .login:
            "/auth/login"
        case .logout:
            "/auth/logout"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .register,
            .verifyEmail,
            .finishRegister,
            .login,
            .logout:
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
        }
    }
    
    var headers: [String : String]? {
        ["Content-Type": "application/json"]
    }
}
