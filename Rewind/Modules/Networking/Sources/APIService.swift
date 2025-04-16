import Moya
import Foundation

enum APIService { }

extension APIService: TargetType {
    var baseURL: URL {
        URL(string: "https://rewindapp.ru")!
    }
    
    var path: String {
        "/path"
    }
    
    var method: Moya.Method {
        .get
    }
    
    var task: Moya.Task {
        .requestPlain
    }
    
    var headers: [String : String]? {
        ["Content-Type": "application/json"]
    }
    
    
}
