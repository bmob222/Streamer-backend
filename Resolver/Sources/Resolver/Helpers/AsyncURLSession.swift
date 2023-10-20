import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// We need this protoocol to tell our async/await runtime about URLSession.
public protocol AsyncURLSession {

    /// Our async/await enabled URL fetcher,
    /// returns an async error or a [ data, response ] tuple.
    func asyncData(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// Here we implement our async aware function.
extension URLSession: AsyncURLSession {

    public func asyncData(for request: URLRequest) async throws -> (Data, URLResponse) {
        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<(Data, URLResponse), Error>) in
            logger.trace("[Resolver] Request", metadata: [
                "request.url": "\(request.url?.absoluteString ?? "")",
                "request.method": "\(request.httpMethod ?? "GET")",
                "request.headers": "\(request.allHTTPHeaderFields?.map { $0.key + ":" + $0.value}.joined(separator: ",") ?? "")"
            ])
            ResolverURLSession.shared.session.dataTask(with: request) { data, response, error in

                guard let data = data, let response = response else {
                    if let error = error {
                        logger.error("[Resolver] error", metadata: [
                            "error": "\(error.localizedDescription)"
                        ])
                        continuation.resume(throwing: error )
                    }
                    return
                }
                if let httpResponse = response as? HTTPURLResponse {
                    let headers = httpResponse.allHeaderFields as? [String: String]
                    logger.trace("[Resolver] response", metadata: [
                        "response.url": "\(httpResponse.url?.absoluteString ?? "")",
                        "response.status": "\(httpResponse.statusCode)",
                        "response.mimeType": "\(httpResponse.mimeType ?? "")",
                        "response.headers": "\(headers?.map { $0.key + ":" + $0.value}.joined(separator: ",") ?? "")"
                    ])
                }

                continuation.resume(returning: (data, response))
            }.resume()
        })
    }
}

public class ResolverURLSession: NSObject, URLSessionDelegate {
    public static let shared = ResolverURLSession()
    let session: URLSession = URLSession(configuration: .default)

    override init() {
        super.init()
    }
}

extension Data {
    var prettyPrintedJSONString: NSString? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: jsonObject,
                                                       options: [.prettyPrinted]),
              let prettyJSON = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
                  return nil
               }

        return prettyJSON
    }
}
