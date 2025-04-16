import Moya
import Foundation

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
