import Foundation
import SwiftSoup

struct YugenAnimeResolver: Resolver {
    let name = "YugenAnime"
    static let domains: [String] = ["yugenanime.tv"]

    enum YugenAnimeResolverError: Error {
        case urlNotValid, contentFetchingError, parsingError
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        // Fetch and parse the main content
        guard let content = try? await Utilities.downloadPage(url: url) else {
            throw YugenAnimeResolverError.contentFetchingError
        }
        let document = try SwiftSoup.parse(content)

        // Extract the src attribute of the iframe with id "main-embed"
        let iframeSrcs = try document.select("iframe#main-embed").array().map {
            try $0.attr("src")
        }

        // Convert relative URLs to absolute URLs and filter out invalid ones
        let validURLs = try iframeSrcs.compactMap { src -> URL? in
            guard var absoluteSrc = URL(string: src, relativeTo: url)?.absoluteString else {
                throw YugenAnimeResolverError.urlNotValid
            }
            if src.starts(with: "//") {
                absoluteSrc = "https:" + src
            }
            return URL(string: absoluteSrc)
        }.first

        guard let validURL = validURLs else {
            throw YugenAnimeResolverError.urlNotValid
        }
        let headers = [
            "Host": "yugenanime.tv",
            "Connection": "keep-alive",
            "sec-ch-ua": "\"Not_A Brand\";v=\"8\", \"Chromium\";v=\"120\", \"Google Chrome\";v=\"120\"",
            "DNT": "1",
            "sec-ch-ua-mobile": "?0",
            "Accept": "*/*",
            "X-Requested-With": "XMLHttpRequest",
            "sec-ch-ua-platform": "\"macOS\"",
            "Origin": "https://yugenanime.tv",
            "Sec-Fetch-Site": "same-origin",
            "Sec-Fetch-Mode": "cors",
            "Sec-Fetch-Dest": "empty",
            "Referer": validURL.absoluteString,
            "Accept-Language": "en-US,en;q=0.9,ar;q=0.8",
            "Pragma": "no-cache",
            "Cache-Control": "no-cache",
            "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8"
        ]

        let embedURL = URL(staticString: "https://yugenanime.tv/api/embed/")
        let body = "id=\(validURL.lastPathComponent)&ac=0".data(using: .utf8)
        let results = try await Utilities.requestData(
            url: embedURL,
            httpMethod: "POST",
            data: body,
            extraHeaders: headers
        )

        let response = try JSONDecoder().decode(EmbedResponse.self, from: results)
        return response.hls.map {
            .init(stream: .init(Resolver: "Yugenanime", streamURL: $0))
        }

    }

    // MARK: - EmbedResponse
    struct EmbedResponse: Codable {
        let sources: [Source]
        let hls: [URL]

        enum CodingKeys: String, CodingKey {
            case sources
            case hls
        }
    }

    // MARK: - Source
    struct Source: Codable {
        let name: String
        let src: URL
        let type: String

        enum CodingKeys: String, CodingKey {
            case name
            case src
            case type
        }
    }

}
