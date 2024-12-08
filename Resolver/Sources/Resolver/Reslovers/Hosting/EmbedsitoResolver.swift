import Foundation

struct EmbedsitoResolver: Resolver {
    let name = "Embedsito"
    static let domains: [String] = ["embedsito.com", "fembed.com", "fembed-hd.com", "suzihaza.com", "www.fembed.com", "vanfem.com","embed69.org"]

    enum EmbedsitoResolverError: Error {
        case urlNotValid
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let path = url.absoluteString.replacingOccurrences(of: "/v/", with: "/api/source/")
        guard let url = URL(string: path) else {
            throw EmbedsitoResolverError.urlNotValid
        }
        let data  = try await Utilities.requestData(url: url, httpMethod: "POST")
        let content = try JSONDecoder().decode(Response.self, from: data)
        return content.data.reversed().map {
            return .init(Resolver: "Fembed.com", streamURL: $0.file, quality: Quality(quality: $0.label), headers: [:])
        }
    }

    struct Response: Codable {
        let success: Bool
        let data: [File]
    }

    // MARK: - Datum
    struct File: Codable {
        let file: URL
        let label, type: String
    }

}
