import Foundation
import SwiftSoup
import CryptoSwift

struct BestXStreamResolver: Resolver {
    let name = "BestX"
    static let domains: [String] = ["bestx.stream"]

    enum BestXStreamResolverError: Error {
        case idNotFound
    }
    func getMediaURL(url: URL) async throws -> [Stream] {
        let content = try await Utilities.downloadPage(url: url)
        let regx = #"MasterJS\s*=\s*'([^']+)"#
        let sourceMatchingExpr = try NSRegularExpression(
            pattern: regx,
            options: .caseInsensitive
        )
        guard let match = sourceMatchingExpr.matches(in: content).first else {
            throw BestXStreamResolverError.idNotFound
        }

        let encoded = content[match, at: 1]
        let decoded = Data(base64Encoded: encoded)!
        let response = try JSONDecoder().decode(AESData.self, from: decoded)

        let password = Data([UInt8](hex: "3456714533234E377A74264845505E61"))
        let salt = Data([UInt8](hex: response.salt))
        let iv =  Data([UInt8](hex: response.iv))
        let iterations = response.iterations
        let ciphertext = Data(base64Encoded: response.ciphertext)!
        let key = try! PKCS5.PBKDF2(password: password.bytes, salt: salt.bytes, iterations: iterations, keyLength: 32, variant: .sha2(.sha512)).calculate()
        let aes = try AES(key: key, blockMode: CBC(iv: iv.bytes), padding: .pkcs5)
        let decrypted = try aes.decrypt(ciphertext.bytes)

        guard let decryptedContent = String(data: Data(decrypted), encoding: .utf8),
              let streamPath = decryptedContent.matches(for: "sources:\\s*\\[\\{\"file\":\"([^\"]+)").first,
              let streamURL = URL(string: streamPath),
              let tracks = decryptedContent.matches(for: "tracks:\\s*\\[(.+)]").first,
              let tracksData = ("[" + tracks + "]").data(using: .utf8) else {
            throw BestXStreamResolverError.idNotFound
        }

        let trackResponse = try JSONDecoder().decode([Tracks].self, from: tracksData)

        let subtitles = trackResponse
            .filter { $0.kind == "captions"}
            .compactMap { track -> Subtitle? in
                guard let label = track.label, let subtitle = SubtitlesLangauge(rawValue: label ) else { return nil}
                return Subtitle(url: track.file, language: subtitle)
            }

        return [.init(Resolver: "PressPlay.top", streamURL: streamURL, subtitles: subtitles)]

    }

    struct AESData: Codable {
        let ciphertext: String
        let iv: String
        let salt: String
        let iterations: Int
    }

    struct Tracks: Codable {
        let file: URL
        let label: String?
        let kind: String
    }

}
