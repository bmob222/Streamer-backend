import Foundation
import SwiftSoup
                                      
struct VoeResolver: Resolver {
    let name = "Voe"
    static let domains: [String] = [
        "voe.sx",
        "voeun-block.net",
        "voe-un-block.com",
        "audaciousdefaulthouse.com",
        "launchreliantcleaverriver.com",
        "reputationsheriffkennethsand.com",
        "fittingcentermondaysunday.com",
        "voe.bar",
        "housecardsummerbutton.com",
        "fraudclatterflyingcar.com",
        "bigclatterhomesguideservice.com",
        "uptodatefinishconferenceroom.com",
        "realfinanceblogcenter.com",
        "tinycat-voe-fashion.com",
        "20demidistance9elongations.com",
        "telyn610zoanthropy.com",
        "toxitabellaeatrebates306.com",
        "greaseball6eventual20.com",
        "745mingiestblissfully.com",
        "19turanosephantasia.com",
        "30sensualizeexpression.com",
        "321naturelikefurfuroid.com",
        "449unceremoniousnasoseptal.com",
        "guidon40hyporadius9.com",
        "cyamidpulverulence530.com",
        "boonlessbestselling244.com",
        "antecoxalbobbing1010.com",
        "matriculant401merited.com",
        "scatch176duplicities.com",
        "35volitantplimsoles5.com",
        "tummulerviolableness.com",
        "tubelessceliolymph.com",
        "availedsmallest.com",
        "counterclockwisejacky.com",
        "monorhinouscassaba.com",
        "urochsunloath.com",
        "simpulumlamerop.com",
        "sizyreelingly.com",
        "rationalityaloelike.com",
        "wolfdyslectic.com",
        "metagnathtuggers.com",
        "gamoneinterrupted.com",
        "chromotypic.com",
        "crownmakermacaronicism.com",
        "generatesnitrosate.com",
        "yodelswartlike.com",
        "figeterpiazine.com",
        "cigarlessarefy.com",
        "valeronevijao.com",
        "strawberriesporail.com",
        "timberwoodanotia.com",
        "phenomenalityuniform.com",
        "prefulfilloverdoor.com",
        "nonesnanking.com",
        "kathleenmemberhistory.com",
        "denisegrowthwide.com",
        "troyyourlead.com",
        "stevenimaginelittle.com",
        "edwardarriveoften.com",
        "lukecomparetwo.com",
        "kennethofficialitem.com",
        "bradleyviewdoctor.com",
        "jamiesamewalk.com",
        "seanshowcould.com",
        "johntryopen.com",
        "morganoperationface.com",
        "markstyleall.com",
        "jayservicestuff.com",
        "vincentincludesuccessful.com",
        "brookethoughi.com",
        "jamesstartstudent.com",
        "ryanagoinvolve.com",
        "jasonresponsemeasure.com",
        "graceaddresscommunity.com"
   
    ]

    enum VoeResolverError: Error {
        case regxValueNotFound
        case urlNotValid

    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        // https://voe.sx/e/cresjbbehpjd
        // https://voe.sx/cresjbbehpjd
        var url = url
        if !url.absoluteString.contains("/e/") {
            url = URL(staticString: "https://voe.sx/e/").appendingPathComponent(url.lastPathComponent)
        }
        let pageContent = try await Utilities.downloadPage(url: url)
        let pageDocument = try SwiftSoup.parse(pageContent)
        let script = try pageDocument.select("script").filter {
            try $0.html().contains("'hls':")
        }.first?.html() ?? ""
        guard let path = Utilities.extractURLs(content: script).filter({ $0.pathExtension == "m3u8"}).last else {
            throw VoeResolverError.urlNotValid
        }
        return [.init(Resolver: "Voe", streamURL: path)]
    }

}
