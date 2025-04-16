import Moya
import Foundation

protocol NetworkServiceProtocol { }

final class NetworkService: NetworkServiceProtocol {
    private let provider = NetworkProvider<APIService>()
}
