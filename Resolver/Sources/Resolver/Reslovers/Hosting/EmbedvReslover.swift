import Foundation
import SwiftSoup
import JavaScriptCore

struct EmbedvReslover: Resolver {
    let name = "Embedv"
    static let domains: [String] = ["embedv.net"]
    private let baseURL: URL = URL(string: "https://embedv.net/")!

    enum EmbedvResloverError: Error {
        case urlNotValid
        case wrongData
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        let html = try await Utilities.downloadPage(url: url)
        let regexPattern = "eval\\(\"window\\.ADBLOCKER\\s*=\\s*false;\\\\n(.+?);\"\\);<\\/script"
        guard var r = html.matches(for: regexPattern).first else {
            throw EmbedvResloverError.urlNotValid
        }
        r = r.replacingOccurrences(of: "\\u002b", with: "+")
        r = r.replacingOccurrences(of: "\\u0027", with: "'")
        r = r.replacingOccurrences(of: "\\u0022", with: "\"")
        r = r.replacingOccurrences(of: "\\/", with: "/")
        r = r.replacingOccurrences(of: "\\\\", with: "\\")
        r = r.replacingOccurrences(of: "\\\"", with: "\"")
        // Use the modified 'r' variable here
        r = decode(r, alt: true)
        let v = r[Range(.init(location: 11, length: r.count-11))!]
        guard let data = v.data(using: .utf8) else {
            throw EmbedvResloverError.wrongData
        }

            // let webURL = url

        let response = try JSONDecoder().decode(EmbedResponse.self, from: data)
        return try response.stream.map {
            var streamURL: URL = $0.url
            if !$0.url.absoluteString.hasPrefix("https://") {
                streamURL = try URL($0.url.absoluteString.replacingOccurrences(of: ":/*", with: "://"))
            }
            let stream = try URL(sigDecode(streamURL.absoluteString))
            return Stream(Resolver: "EmbedV", streamURL: stream, quality: Quality(quality: $0.label), headers: ["Referer": url.absoluteString])
        }
    }
    func sigDecode(_ url: String) -> String {
        let sig = url.components(separatedBy: "sig=")[1].components(separatedBy: "&")[0]
        var t = ""
        for v in sig.hexDecodedData {
            t += String(Character(UnicodeScalar((v as! UInt8) ^ 2)))
        }
        t = String(String(data: Data(base64Encoded: t + "==")!, encoding: .utf8)!.dropLast(5).reversed())
        var tArray = Array(t)
        for i in stride(from: 0, to: tArray.count - 1, by: 2) {
            tArray.swapAt(i, i + 1)
        }
        let newURL = url.replacingOccurrences(of: sig, with: String(tArray.dropLast(5)))
        return newURL
    }

    struct EmbedResponse: Codable {
        let stream: [SStream]
        let hash: String

        enum CodingKeys: String, CodingKey {
            case stream
            case hash
        }
    }

    // MARK: - Stream
    struct SStream: Codable {
        let type: String
        let label: String
        let url: URL

        enum CodingKeys: String, CodingKey {
            case type = "Type"
            case label = "Label"
            case url = "URL"
        }
    }

}

extension String {
        var hexDecodedData: [Any] {
            var hex = self
            var data = [Any]()
            while !hex.isEmpty {
                let index = hex.index(hex.startIndex, offsetBy: 2)
                let substr = String(hex[..<index])
                hex = String(hex[index...])
                if let byte = UInt8(substr, radix: 16) {
                    data.append(byte)
                }
            }
            return data
        }
    }

func decode(_ text: String, alt: Bool = false) -> String {
    var text = text.replacingOccurrences(of: "\\s+|/\\*.*?\\*/", with: "", options: .regularExpression)
    let data: String
    let chars: [String]
    let char1: String
    let char2: String

    if alt {
        data = text.components(separatedBy: "+(ﾟɆﾟ)[ﾟoﾟ]")[1]
        chars = Array(data.components(separatedBy: "+(ﾟɆﾟ)[ﾟεﾟ]+").dropFirst())
        char1 = "ღ"
        char2 = "(ﾟɆﾟ)[ﾟΘﾟ]"
    } else {
        data = text.components(separatedBy: "+(ﾟДﾟ)[ﾟoﾟ]")[1]
        chars = Array(data.components(separatedBy: "+(ﾟДﾟ)[ﾟεﾟ]+").dropFirst())
        char1 = "c"
        char2 = "(ﾟДﾟ)['0']"
    }

    var txt = ""
    for char in chars {
        var char = char
            .replacingOccurrences(of: "(oﾟｰﾟ)", with: "u")
            .replacingOccurrences(of: char1, with: "0")
            .replacingOccurrences(of: char2, with: "c")
            .replacingOccurrences(of: "ﾟΘﾟ", with: "1")
            .replacingOccurrences(of: "!+[]", with: "1")
            .replacingOccurrences(of: "-~", with: "1+")
            .replacingOccurrences(of: "o", with: "3")
            .replacingOccurrences(of: "_", with: "3")
            .replacingOccurrences(of: "ﾟｰﾟ", with: "4")
            .replacingOccurrences(of: "(+", with: "(")
        char = char.replacingOccurrences(of: "\\((\\d)\\)", with: "$1", options: .regularExpression)
        let context = JSContext()!

        var c = ""
        var subchar = ""
        for v in char {
            c += String(v)
            do {
                let x = c
                let results = try context.evaluateScript(x)!
                if results.isUndefined {
                    throw EmbedvReslover.EmbedvResloverError.urlNotValid
                }
                subchar += try results.toString()
                c = ""
            } catch {
                continue
            }
        }
        if !subchar.isEmpty {
            txt += subchar + "|"
        }
    }
    txt = txt.dropLast().replacingOccurrences(of: "+", with: "")

    let txtResult = txt.split(separator: "|").map { String($0) }.compactMap { Int($0, radix: 8) }.compactMap { UnicodeScalar($0) }.map { String($0) }.joined()

    return toStringCases(txtResult)
}

func toStringCases(_ txtResult: String) -> String {
    var txtResult = txtResult
    var sumBase = ""
    var m3 = false
    var txtTemp: [(String, String)] = []

    if txtResult.contains(".toString(") {
        if txtResult.contains("+(") {
            m3 = true
            if let sumBaseMatch = txtResult.range(of: ".toString...(\\d+).", options: .regularExpression) {
                sumBase = "+" + String(txtResult[sumBaseMatch].dropFirst(11).dropLast(1))
            }
            let txtPreTemp = txtResult.matches(ffor: "..(\\d),(\\d+).")
            txtTemp = txtPreTemp.map { ($0[1], $0[0]) }
        } else {
            let txtPreTemp = txtResult.matches(ffor: "(\\d+)\\.0.\\w+.([^\\)]+).")
            txtTemp = txtPreTemp.map { ($0[0], $0[1]) }
        }

        for (numero, base) in txtTemp {
            let code = toString(Int(numero)!, Int(base)! + Int(sumBase)!)
            if m3 {
                txtResult = txtResult.replacingOccurrences(of: "\"|\\+", with: "", options: .regularExpression).replacingOccurrences(of: "(\(base),\(numero))", with: code)
            } else {
                txtResult = txtResult.replacingOccurrences(of: "'|\\+", with: "", options: .regularExpression).replacingOccurrences(of: "\(numero).0.toString(\(base))", with: code)
            }
        }
    }

    return txtResult
}

func toString(_ number: Int, _ base: Int) -> String {
    let string = "0123456789abcdefghijklmnopqrstuvwxyz"
    if number < base {
        return String(string[string.index(string.startIndex, offsetBy: number)])
    } else {
        return toString(number / base, base) + String(string[string.index(string.startIndex, offsetBy: number % base)])
    }
}

extension String {
    func matches(ffor regex: String) -> [[String]] {
        do {
            let regex = try NSRegularExpression(pattern: regex)
            let results = regex.matches(in: self, range: NSRange(self.startIndex..., in: self))
            return results.map { result in
                (0..<result.numberOfRanges).map {
                    String(self[Range(result.range(at: $0), in: self)!])
                }
            }
        } catch {
            return []
        }
    }
}
