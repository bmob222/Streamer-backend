import Foundation
import SwiftSoup
import CryptoSwift

struct Fstream365Resolver: Resolver {
    let name = "Fstream365"
    static let domains: [String] = ["fstream365.com"]

    @EnviromentValue(key: "mycloud_keys_url", defaultValue: URL(staticString: "https://google.com"))
    var keysURL: URL

    func getMediaURL(url: URL) async throws -> [Stream] {

        let info = url.absoluteString
            .replacingOccurrences(of: "https://", with: "")
        let eURL = keysURL.appending("url", value: info.encodeURIComponent())
        let encodedPath = try await Utilities.downloadPage(url: eURL)
        let encodedURL = try URL(encodedPath)
        let headers = [
            "User-Agent": Constants.userAgent,
            "Referer": url.absoluteString,
            "origin": url.absoluteString,
            "content-type": "application/json",
            "X-Requested-With": "XMLHttpRequest",
            "Sec-Fetch-Mode": "cors",
            "Sec-Fetch-Site": "same-origin"
        ]

        let data = try await Utilities.requestData(url: encodedURL, extraHeaders: headers)
        let response = try JSONCoder.decoder.decode(Response.self, from: data)
        return response.sources.map {
            let subtitles = response.tracks.compactMap { track -> Subtitle? in
                guard let label = track.label, let lan = label.components(separatedBy: "-").first, let subtitle = SubtitlesLangauge(rawValue: lan), let file = track.file else { return  nil }
                return Subtitle(url: file, language: subtitle)
            }
            return .init(Resolver: "Fstream365", streamURL: $0.file, subtitles: subtitles)
        }
    }

    struct Response: Decodable {
        let sources: [ResponseSource]
        let tracks: [Track]
    }
    // MARK: - Source
    struct ResponseSource: Codable {
        let file: URL
        let type: String

        enum CodingKeys: String, CodingKey {
            case file
            case type
        }
    }

    struct Message: Codable {
        let sid: String
    }
    // MARK: - Track
    struct Track: Codable {
        let file: URL?
        let label: String?
        let kind: String

        enum CodingKeys: String, CodingKey {
            case file
            case label
            case kind
        }
    }

}

private func EvpKDF(
    password: [UInt8],
    keySize: Int,
    ivSize: Int,
    salt: [UInt8],
    iterations: Int = 1,
    resultKey: inout [UInt8],
    resultIv: inout [UInt8]
) {
    let keySize = keySize / 8
    let ivSize = ivSize / 8
    let targetKeySize = keySize + ivSize
    var derivedBytes = [UInt8](repeating: 0, count: targetKeySize)
    var numberOfDerivedWords = 0
    var block = [UInt8]()

    while numberOfDerivedWords < targetKeySize {
        if !block.isEmpty {
            block.append(contentsOf: password)
        } else {
            block = password
        }
        block = hmac(key: block, data: salt)
        var finalBlock = block

        for _ in 1..<iterations {
            finalBlock = hmac(key: finalBlock, data: block)
        }

        derivedBytes.replaceSubrange(
            numberOfDerivedWords..<(numberOfDerivedWords + min(finalBlock.count, targetKeySize - numberOfDerivedWords)),
            with: finalBlock
        )

        numberOfDerivedWords += finalBlock.count
    }

    resultKey = Array(derivedBytes[0..<keySize])
    resultIv = Array(derivedBytes[keySize..<(keySize + ivSize)])
}

private func hmac(key: [UInt8], data: [UInt8]) -> [UInt8] {
    do {
        let hmac = try HMAC(key: key, variant: .md5).authenticate(data)
        return hmac
    } catch {
        logger.error("Hmac error \(error)")
        return []
    }
}
