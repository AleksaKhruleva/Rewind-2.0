import Foundation

public struct JWTDecoderService {
    
    public init() {}
    
    public func decode(jwtToken: String) -> [String: Any]? {
        let segments = jwtToken.components(separatedBy: ".")
        guard segments.count > 1 else { return nil }
        
        var base64String = segments[1]
        let remainder = base64String.count % 4
        if remainder > 0 {
            base64String += String(repeating: "=", count: 4 - remainder)
        }
        
        guard let data = Data(base64Encoded: base64String),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return nil
        }
        
        return json
    }
    
    public func getUserId(from jwtToken: String) -> String? {
        guard let payload = decode(jwtToken: jwtToken),
              let intId = payload["user_id"] as? Int else { return nil }
        return String(intId)
    }
}
