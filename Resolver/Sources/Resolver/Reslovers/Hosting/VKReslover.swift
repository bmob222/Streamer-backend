import Foundation
import SwiftSoup

struct VKReslover: Resolver {
    let name = "VK"
    static let domains: [String] = ["vk.com"]
    
    enum VKResloverError: Error {
        case urlNotValid
        case wrongData
    }
    
    func getMediaURL(url: URL) async throws -> [Stream] {
        let headers = [
            "Accept" : "*/*",
            "Origin" : "https://vk.com",
            "Referer" : "https://vk.com/",
        ]
        let html = try await Utilities.downloadPage(url: url, encoding: .windowsCP1251)
        let regexPattern = #"url(\d+)\":\"(.*?)\""#
        let regex = try NSRegularExpression(pattern: regexPattern)
        let results = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))
        let nsString = html as NSString
        return results.compactMap {
            let quality = nsString.substring(with: $0.range(at: 1))
            let path = nsString.substring(with: $0.range(at: 2)).replacingOccurrences(of: "\\/", with: "/")
            guard let url = URL(string: path) else {
                return nil
            }
            return Stream(Resolver: "VK", streamURL: url, quality: Quality(quality: quality), headers: headers)
        }
    }
}
