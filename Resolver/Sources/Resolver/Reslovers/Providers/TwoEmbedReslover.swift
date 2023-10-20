import Foundation
import SwiftSoup

struct TwoEmbedResolver: Resolver {
    let name = "2embed"

    static let domains: [String] = ["2embed.to"]
    let baseURL: URL = URL(staticString: "https://2embed.to")

    enum TwoEmbedResolverError: Error {
        case capchaKeyNotFound
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)
        let captchaURL = try pageDocument.select("script[src*=https://www.google.com/recaptcha/api.js?render=]").attr("src")

        guard let range = captchaURL.range(of: "render=") else {
            throw TwoEmbedResolverError.capchaKeyNotFound
        }

        let captchaKey = String(captchaURL[range.upperBound...])
        return try await pageDocument.select(".dropdown-menu a[data-id]")
            .array()
            .asyncMap { row -> [Stream]? in
                let serverId =  try row.attr("data-id")
                guard let token = try await Self.getCaptchaToken(url: url, key: captchaKey) else {
                    throw TwoEmbedResolverError.capchaKeyNotFound
                }
                let serverURL = baseURL.appendingPathComponent("ajax/embed/play")
                    .appendingQueryItem(name: "id", value: serverId)
                    .appendingQueryItem(name: "_token", value: token)
                let data = try await Utilities.requestData(url: serverURL, extraHeaders: ["referer": url.absoluteString])
                let embed = try JSONCoder.decoder.decode(EmbedJSON.self, from: data)
                let subtitles = try await self.getSubtitles(url: embed.link)
                return try? await HostsResolver.resolveURL(url: embed.link).map {
                    Stream(stream: $0, subtitles: subtitles)
                }
            }
            .compactMap { $0 }
            .flatMap { $0 }
    }

    func getSubtitles(url: URL) async throws -> [Subtitle] {
        var subtitles: [Subtitle] = []
        if let subtitleInfo = url.queryParameters?["sub.info"],
           let subtitleURL = URL(string: subtitleInfo) {
            let data = try await Utilities.requestData(url: subtitleURL)
            let subtitlesResponse = try JSONCoder.decoder.decode([SubtitleResponse].self, from: data)

            subtitles = subtitlesResponse.compactMap {
                if let language = SubtitlesLangauge(rawValue: $0.label) {
                    return Subtitle(url: $0.file, language: language)
                } else {
                    return nil
                }
            }
        }
        return subtitles
    }

    struct EmbedJSON: Codable {
        let link: URL
    }
    struct SubtitleResponse: Codable {
        let file: URL
        let label: String
        let kind: String
    }

    static func getCaptchaToken(url: URL, key: String, referer: String = "") async throws -> String? {
        let vTokenRegex = try! NSRegularExpression(
            pattern: #"releases/([^/&?#]+)"#,
            options: .caseInsensitive
        )
        let tokenRegex =  try! NSRegularExpression(
            pattern: #"rresp\",\"(.+?)\""#,
            options: .caseInsensitive
        )

        let domain = "https://\(url.host!):443".data(using: .utf8)?.base64EncodedString().replacingOccurrences(of: "=", with: "") ?? ""
        let vTokenPage = try await Utilities.downloadPage(url: URL(string: "https://www.google.com/recaptcha/api.js?render=\(key)")!,
                                                          extraHeaders: ["referrer": referer])

        guard let vToken = vTokenRegex.firstMatch(in: vTokenPage)?.firstMatchingGroup else {
            return nil
        }
        let recapTokenPageContent = try await Utilities.downloadPage(url: URL(string: "https://www.google.com/recaptcha/api2/anchor?ar=1&hi=en&size=invisible&cb=123456789&k=\(key)&co=\(domain)&v=\(vToken)")!)
        let pageDocument = try SwiftSoup.parse(recapTokenPageContent)
        guard let recapToken = try pageDocument.select("#recaptcha-token").array().first?.attr("value") else {
            return nil
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        let extraHeaders = [
            "Content-Type": "multipart/form-data; boundary=\(boundary)"
        ]
        let postData = [
            "v": vToken,
            "k": key,
            "c": recapToken,
            "co": domain,
            "sa": "",
            "reason": "q"
        ]
        let httpBody = NSMutableData()

        for (key, value) in postData {
            httpBody.appendString(convertFormField(named: key, value: value, using: boundary))
        }
        httpBody.appendString("--\(boundary)--")

        let reloadPageContent = try await Utilities.downloadPage(url: URL(string: "https://www.google.com/recaptcha/api2/reload?k=\(key)")!,
                                                                 httpMethod: "POST",
                                                                 data: httpBody as Data,
                                                                 extraHeaders: extraHeaders)
        return tokenRegex.firstMatch(in: reloadPageContent)?.firstMatchingGroup
    }

    static func convertFormField(named name: String, value: String, using boundary: String) -> String {
        var fieldString = "--\(boundary)\r\n"
        fieldString += "Content-Disposition: form-data; name=\"\(name)\"\r\n"
        fieldString += "\r\n"
        fieldString += "\(value)\r\n"

        return fieldString
    }

}
