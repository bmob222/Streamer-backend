import Foundation

struct M3u8Parser {
    static func getQuality(stream: Stream) async throws -> Stream? {
        let file = try await Utilities.downloadPage(url: stream.streamURL, extraHeaders: stream.headers ?? [:])
        let pattern = "RESOLUTION=(\\d+x\\d+)"
        let regex = try NSRegularExpression(pattern: pattern)
        let matches = regex.matches(in: file, options: [], range: NSRange(location: 0, length: file.count))
        var bestHeight = 0
        var bestArea = 0
        for match in matches {
            let resolutionRange = Range(match.range(at: 1), in: file)!

            let resolution = String(file[resolutionRange])

            let components = resolution.components(separatedBy: "x")
            let width = Int(components[0])!
            let height = Int(components[1])!
            let area = width * height
            if area > bestArea {
                bestArea = area
                bestHeight = height
            }
        }
        if let quality = Quality(height: bestHeight) {
            return Stream(stream: stream, quality: quality)
        } else {
            return nil
        }

    }
}
