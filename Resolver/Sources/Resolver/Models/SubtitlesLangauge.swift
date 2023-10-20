import Foundation

public enum SubtitlesLangauge: String, Codable, CaseIterable {

    case afrikaans = "Afrikaans"
    case albanian = "Albanian"
    case arabic = "Arabic"
    case aragonese = "Aragonese"
    case armenian = "Armenian"
    case asturian = "Asturian"
    case basque = "Basque"
    case bengali = "Bengali"
    case bosnian = "Bosnian"
    case breton = "Breton"
    case belarusian = "Belarusian"
    case bulgarian = "Bulgarian"
    case burmese = "Burmese"
    case catalan = "Catalan"
    case chineseBilingual = "Chinese (Bilingual)"
    case chineseSimplified = "Chinese (Simplified)"
    case chineseTraditional = "Chinese (Traditional)"
    case croatian = "Croatian"
    case czech = "Czech"
    case danish = "Danish"
    case dutch = "Dutch"
    case english = "English"
    case esperanto = "Esperanto"
    case estonian = "Estonian"
    case finnish = "Finnish"
    case french = "French"
    case georgian = "Georgian"
    case galician = "Galician"
    case german = "German"
    case greek = "Greek"
    case hebrew = "Hebrew"
    case hindi = "Hindi"
    case hungarian = "Hungarian"
    case icelandic = "Icelandic"
    case indonesian = "Indonesian"
    case italian = "Italian"
    case japanese = "Japanese"
    case kazakh = "Kazakh"
    case khmer = "Khmer"
    case korean = "Korean"
    case latvian = "Latvian"
    case lithuanian = "Lithuanian"
    case luxembourgish = "Luxembourgish"
    case macedonian = "Macedonian"
    case malay = "Malay"
    case manipuri = "Manipuri"
    case mongolian = "Mongolian"
    case malayalam = "Malayalam"
    case norwegian = "Norwegian"
    case occitan = "Occitan"
    case persian = "Persian"
    case polish = "Polish"
    case portuguese = "Portuguese"
    case portugueseBrazilian = "Portuguese (Brazilian)"
    case romanian = "Romanian"
    case montenegrin = "Montenegrin"
    case russian = "Russian"
    case serbian = "Serbian"
    case sinhalese = "Sinhalese"
    case slovak = "Slovak"
    case slovenian = "Slovenian"
    case spanish = "Spanish"
    case swahili = "Swahili"
    case swedish = "Swedish"
    case syriac = "Syriac"
    case tamil = "Tamil"
    case telugu = "Telugu"
    case tagalog = "Tagalog"
    case thai = "Thai"
    case turkish = "Turkish"
    case ukrainian = "Ukrainian"
    case urdu = "Urdu"
    case uzbek = "Uzbek"
    case vietnamese = "Vietnamese"

    case chinese = "Chinese"
    case farsi = "Farsi/Persian"
    case kannada = "Kannada"
    case norwegianBokmål = "Norwegian Bokmål"
    case spanishLatinAmerica = "Spanish (LA)"

    case unknown = "Unknown"

    public var code: String? {
        switch self {
        case .afrikaans:
            return "af"
        case .albanian:
            return "sq"
        case .arabic:
            return "ar"
        case .aragonese:
            return "an"
        case .armenian:
            return "hy"
        case .asturian:
            return "at"
        case .basque:
            return "eu"
        case .bengali:
            return "be"
        case .bosnian:
            return "bn"
        case .breton:
            return "bs"
        case .belarusian:
            return "br"
        case .bulgarian:
            return "bg"
        case .burmese:
            return "my"
        case .catalan:
            return "ca"
        case .chineseBilingual:
            return "ze"
        case .chineseSimplified:
            return "zh-cn"
        case .chineseTraditional:
            return "zh-tw"
        case .croatian:
            return "hr"
        case .czech:
            return "cs"
        case .danish:
            return "da"
        case .dutch:
            return "nl"
        case .english:
            return "en"
        case .esperanto:
            return "eo"
        case .estonian:
            return "et"
        case .finnish:
            return "fi"
        case .french:
            return "fr"
        case .georgian:
            return "gl"
        case .galician:
            return "ka"
        case .german:
            return "de"
        case .greek:
            return "el"
        case .hebrew:
            return "he"
        case .hindi:
            return "hi"
        case .hungarian:
            return "hu"
        case .icelandic:
            return "is"
        case .indonesian:
            return "id"
        case .italian:
            return "it"
        case .japanese:
            return "ja"
        case .kazakh:
            return "kk"
        case .khmer:
            return "km"
        case .korean:
            return "ko"
        case .latvian:
            return "lv"
        case .lithuanian:
            return "lt"
        case .luxembourgish:
            return "lb"
        case .macedonian:
            return "mk"
        case .malay:
            return "ms"
        case .manipuri:
            return "ml"
        case .mongolian:
            return "ma"
        case .malayalam:
            return "mn"
        case .norwegian:
            return "me"
        case .occitan:
            return "oc"
        case .persian:
            return "fa"
        case .polish:
            return "pl"
        case .portuguese:
            return "pt-pt"
        case .portugueseBrazilian:
            return "pt-br"
        case .romanian:
            return "ro"
        case .russian:
            return "ru"
        case .montenegrin:
            return "cnr"
        case .serbian:
            return "sr"
        case .sinhalese:
            return "si"
        case .slovak:
            return "sk"
        case .slovenian:
            return "sl"
        case .spanish:
            return "es"
        case .swahili:
            return "sw"
        case .swedish:
            return "sv"
        case .syriac:
            return "sy"
        case .tamil:
            return "tl"
        case .telugu:
            return "ta"
        case .tagalog:
            return "te"
        case .thai:
            return "th"
        case .turkish:
            return "tr"
        case .ukrainian:
            return "uk"
        case .urdu:
            return "ur"
        case .uzbek:
            return "uz"
        case .vietnamese:
            return "vi"
        case .chinese:
            return "zh"
        case .farsi:
            return "fa"
        case .kannada:
            return "kn"
        case .norwegianBokmål:
            return "nb"
        case .spanishLatinAmerica:
            return "es"
        case .unknown:
            return "all"
        }
    }
}
