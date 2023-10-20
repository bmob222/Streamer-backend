import Foundation
import SwiftSoup

struct StreamtapeResolver: Resolver {
    let name = "Streamtape"

    static let domains: [String] = [
        "streamtape.com", "streamtapeadblock.art", "streamtape.to"
    ]

    enum StreamtapeResolverError: Error {
        case urlNotValid
        case redirectTokenNotFound
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        guard let embedUrl = URL(string: url.absoluteString.replacingOccurrences(of: "/v/", with: "/e/")) else {
            throw StreamtapeResolverError.urlNotValid
        }

        let content = try await  Utilities.downloadPage(url: embedUrl)
        let document = try SwiftSoup.parse(content)
        let path = try document.select("#ideoolink").text()
        let tokenPattern = #"getElementById\('robotlink'\)\.innerHTML[^\n]*token=(?<token>[A-Za-z0-9-_]*)"#
        let tokenRegex = try NSRegularExpression(pattern: tokenPattern, options: [])

        guard let tokenMatch = tokenRegex.firstMatch(in: content, options: [], range: NSRange(location: 0, length: content.count)) else {
            throw StreamtapeResolverError.redirectTokenNotFound
        }

        let tokenMatchRange = tokenMatch.range(at: 1)
        guard let tokenRange = Range(tokenMatchRange, in: content) else {
            throw StreamtapeResolverError.redirectTokenNotFound
        }

        let token = String(content[tokenRange])

        guard var urlComponents = URLComponents(string: "https:/\(path)&stream=1"),
              let index = urlComponents.queryItems?.firstIndex(where: { item in
                  item.name == "token"
              }) else {
            throw StreamtapeResolverError.urlNotValid
        }

        urlComponents.queryItems?.remove(at: index)
        urlComponents.queryItems?.append(.init(name: "token", value: token))

        guard let streamURL = urlComponents.url else {
            throw StreamtapeResolverError.urlNotValid

        }
        return [.init(Resolver: "StreamTape", streamURL: streamURL)]
    }
}
