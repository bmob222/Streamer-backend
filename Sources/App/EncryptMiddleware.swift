import Vapor
import Resolver

struct EncryptMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        Resolver.logger = request.logger
        let response = try await next.respond(to: request)
        guard request.url.string != "/metrics" else {
            return response
        }

        let iv = Environment.get("AES_IV") ?? ""
        let key = Environment.get("AES_KEY") ?? ""
        let responseBody = response.body.string ?? ""
        request.logger.trace(
            "response before encryption",
            metadata: [
                "request_url": "\(request.url.path)",
                "headers": "\(request.headers.debugDescription)",
                "remoteAddress": "\(request.remoteAddress?.ipAddress ?? "")"
            ]
        )
        if let encrypted = responseBody.aesEncrypt(key: key, iv: iv) {
            return Response(status: .ok, body: .init(string: encrypted))
        } else {
            return Response(status: .unauthorized)
        }
    }
}
