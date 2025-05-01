import Moya
import Foundation

public enum HTTPError: Error {
    case conflict
    
    case error // temporary
}

final class NetworkProvider<T: TargetType> {
    private let provider: MoyaProvider<T>

    init(stub: Bool = false) {
        self.provider = MoyaProvider<T>(stubClosure: stub ? MoyaProvider.immediatelyStub : MoyaProvider.neverStub)
    }

    func request<D: Decodable>(_ target: T, type: D.Type) async throws -> D {
        try await withCheckedThrowingContinuation { continuation in
            provider.request(target) { result in
                switch result {
                case .success(let response):
                    if response.statusCode == 409 {
                        continuation.resume(throwing: HTTPError.conflict)
                        return
                    }
                    
//                    guard response.statusCode >= 200, response.statusCode < 300 else {
//                        continuation.resume(throwing: HTTPError.error)
//                    }
                    
                    do {
                        let decoded = try JSONDecoder().decode(D.self, from: response.data)
                        continuation.resume(returning: decoded)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
