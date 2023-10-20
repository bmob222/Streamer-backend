import Foundation
import SwiftSoup

struct RealDebridResolver: Resolver {
    let name = "RealDebrid"
    let token = ""
    let regexs = [
        "(http|https):\\/\\/(\\w+\\.)?(1fichier\\.com|alterupload\\.com|cjoint\\.net|desfichiers\\.com|dfichiers\\.com|megadl\\.fr|mesfichiers\\.org|piecejointe\\.net|pjointe\\.com|tenvoi\\.com|dl4free\\.com)\\/\\?([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/[a-z0-9]+\\.(1fichier\\.com|alterupload\\.com|cjoint\\.net|desfichiers\\.com|dfichiers\\.com|megadl\\.fr|mesfichiers\\.org|piecejointe\\.net|pjointe\\.com|tenvoi\\.com|dl4free\\.com)([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?2shared\\.com\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?4shared\\.com\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?anzfile\\.net\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?alfafile\\.net\\/file\\/[0-9A-Za-z]+",
        "(http|https):\\/\\/(\\w+\\.)?backin\\.net\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?bayfiles\\.com\\/[0-9a-zA-Z]{10}",
        "(http|https):\\/\\/(\\w+\\.)?dl\\.bdupload\\.in\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?bdupload\\.asia\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?brupload\\.net\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?btafile\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?catshare\\.net\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?clicknupload\\.(me|com|link|org|co|cc|to|club|red|click)\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?cosmobox\\.org\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?clipwatching\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?highstream\\.tv\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?datafilehost\\.com\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?dailyuploads\\.net\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?ddl\\.to\\/d\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?ddl\\.to\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?ddownload\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?douploads\\.net\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?dropapk\\.to\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?drop\\.download\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?easybytez\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?daofile\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?depositfiles\\.(com|org)\\/(en|fr|de)\\/files\\/[0-9a-z]{9}",
        "(http|https):\\/\\/(\\w+\\.)?depositfiles\\.(com|org)\\/files\\/[0-9a-z]{9}",
        "(http|https):\\/\\/(\\w+\\.)?dfiles\\.(eu|ru)\\/files\\/[0-9a-z]{9}",
        "(http|https):\\/\\/(docs|drive)\\.google\\.com\\/(file|document)\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(docs|drive)\\.google\\.com\\/open([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/dl\\.free\\.fr\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?earn4files\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?extmatrix\\.com\\/(files|get)\\/[0-9a-zA-Z]+[0-9]{10}",
        "(http|https):\\/\\/(\\w+\\.)?extmatrix\\.com\\/(files|get)\\/[0-9A-Z]{8}",
        "(http|https):\\/\\/(\\w+\\.)?ex-load\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?fastclick\\.to\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?fboom\\.me\\/file\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?file\\.al\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?filer\\.net\\/get\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?file4safe\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?file-up\\.org\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?filefox\\.cc\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?fileupload\\.pw\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?filespace\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?filenext\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?filezip\\.cc\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?filefactory\\.com\\/(file|stream)\\/[0-9a-z]{7,}",
        "(http|https):\\/\\/(\\w+\\.)?(filerio|filekeen)\\.(com|in)\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?faststore\\.org\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?fireget\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?flashbit\\.cc\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?filesflash\\.(com|net)\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?flashx\\.(tv|ws|cc|bz|co|pw)\\/[0-9a-z]{12}\\.html",
        "(http|https):\\/\\/(\\w+\\.)?flashx\\.(tv|ws|cc|bz|co|pw)\\/embed-[0-9a-z]{12}\\.html",
        "(http|https):\\/\\/(\\w+\\.)?flashx\\.(tv|ws|cc|bz|co|pw)\\/reloadit([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "\\/\\/(\\w+\\.)?flashx\\.(tv|ws|cc|bz|co|pw)\\/dl([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?florenfile\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?fshare\\.vn\\/file\\/[0-9A-Z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?gigapeta\\.com\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?goloady\\.com\\/file\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?gounlimited\\.to\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?hulkshare\\.com\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?heroupload\\.com\\/[0-9a-z]{16}",
        "(http|https):\\/\\/(\\w+\\.)?hexupload\\.net\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?hotlink\\.cc\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?icerbox\\.com\\/[0-9a-zA-Z]{8}",
        "(http|https):\\/\\/(\\w+\\.)?inclouddrive\\.com\\/file\\/[0-9a-zA-Z_-]{22}",
        "(http|https):\\/\\/(\\w+\\.)?isra\\.cloud\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?isra\\.cloud\\/(.*)id=[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?katfile\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?keep2share\\.(cc|com)\\/file\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?(k2s|keep2s|k2share)\\.cc\\/file\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?load\\.to\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?letsupload\\.cc\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?mdiaload\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?mediafire\\.com\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?mega\\.co\\.nz\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?mega\\.nz\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?mixdrop\\.(co|club|sx|to)\\/(f|e)\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?mixloads\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?mp4upload\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?nitroflare\\.com\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?nelion\\.me\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?ninjastream\\.to\\/(watch|download)\\/[0-9a-zA-Z]{13}",
        "(http|https):\\/\\/(\\w+\\.)?oboom\\.com\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?prefiles\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?rapidvideo\\.com\\/(d|v|e|embed)\\/[0-9A-Z]{10}",
        "(http|https):\\/\\/(\\w+\\.)?rapidrar\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?rapidvid\\.to\\/(d|v|e|embed)\\/[0-9A-Z]{10}",
        "(http|https):\\/\\/(\\w+\\.)?rapidgator\\.(net|asia)\\/file\\/[0-9a-z]{32}",
        "(http|https):\\/\\/(\\w+\\.)?rapidgator\\.(net|asia)\\/file\\/[0-9]{6,12}([^(\\/| |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?rarefile\\.net\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?rg\\.to\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?real-debrid\\.com\\/d\\/[0-9A-Z]{13}",
        "(http|https):\\/\\/(\\w+\\.)?redtube\\.com\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?redbunker\\.net\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?rapidu\\.net\\/[0-9]+",
        "(http|https):\\/\\/(\\w+\\.)?rockfile\\.(eu|co)\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?rutube\\.ru\\/(video|embed|play\\/embed)\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?(salefiles|wupfile)\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?scribd\\.com\\/(doc|presentation|document)\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?sendit\\.cloud\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?(4downfiles|speed-down)\\.org\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?sendspace\\.com\\/(file|pro)\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?simfileshare\\.net\\/download\\/[0-9]+",
        "(http|https):\\/\\/(\\w+\\.)?soundcloud\\.com\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?sky\\.fm\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?streamtape\\.com\\/(v|e)\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?adblockeronstreamtape\\.com\\/(v|e)\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?strcloud\\.link\\/(v|e)\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?strcloud\\.sx\\/(v|e)\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?streamon\\.to\\/d\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?radiotunes\\.com\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?solidfiles\\.com\\/v\\/[0-9a-z]{13}",
        "(http|https):\\/\\/(\\w+\\.)?solidfiles\\.com\\/d\\/[0-9a-z]+\\/",
        "(http|https):\\/\\/(\\w+\\.)?takefile\\.link\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?(turbobit|turbobit5)\\.(net|cc|pw)\\/download\\/free\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?(turbobit|turbobit5)\\.(net|cc|pw)\\/[0-9a-z]{12}\\.html",
        "(http|https):\\/\\/(\\w+\\.)?(turbobit|turbobit5)\\.(net|cc|pw)\\/[0-9a-z]{12}\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?turbo\\.to\\/download\\/free\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?turbo\\.to\\/[0-9a-z]{12}\\.html",
        "(http|https):\\/\\/(\\w+\\.)?turbobif\\.com\\/download\\/free\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?turbobif\\.com\\/[0-9a-z]{12}\\.html",
        "(http|https):\\/\\/(\\w+\\.)?turb\\.(to|cc)\\/download\\/free\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?turb\\.(to|cc)\\/[0-9a-z]{12}\\.html",
        "(http|https):\\/\\/(\\w+\\.)?(hitfile.net|hitf.to|hitf.cc)\\/[0-9a-zA-Z]{7}",
        "(http|https):\\/\\/(\\w+\\.)?tusfiles\\.(net|com)\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?tezfiles\\.com\\/file\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?unibytes\\.com\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?ubiqfile\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?uploadc\\.(com|ch)\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?uploaded\\.(to|net)\\/file\\/[0-9a-z]{6,8}([^(\\/| |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?ul\\.to\\/[0-9a-z]{8}",
        "(http|https):\\/\\/(\\w+\\.)?uploadbox\\.io\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?uploadrar\\.net\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?uploadgig\\.com\\/file\\/download\\/[0-9a-zA-Z]{16}",
        "(http|https):\\/\\/(\\w+\\.)?uppit\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?usersdrive\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?uploadboy\\.(me|com)\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?ulozto\\.(net|cz|sk)\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?pornfile\\.cz\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?zachowajto\\.pl\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?uloz\\.to\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?upload\\.af\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?uploadev\\.org\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?upstream\\.to\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?upstore\\.net\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?(uptobox|uptostream)\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?userscloud\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?vidcloud\\.(co|ru)\\/v\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?videobin\\.co\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?vidoza\\.(net|co|org)\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?vidoza\\.(net|co|org)\\/embed-[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?vimeo\\.com\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?vidlox\\.(tv|me)\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?vidlox\\.(tv|me)\\/embed-[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?voe\\.sx\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?voe\\.sx\\/e\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?v-o-e-unblock\\.net\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?v-o-e-unblock\\.net\\/e\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?voeun-block\\.net\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?voeun-block\\.net\\/e\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?voe-unblock\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?voe-unblock\\.com\\/e\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?voe-unblock\\.net\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?voe-unblock\\.net\\/e\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?voeunblock\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?voeunblock\\.com\\/e\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?voeunblock[0-9]+\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?voeunblock[0-9]+\\.com\\/e\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?voeunbl0ck\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?voeunbl0ck\\.com\\/e\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?voeunblck\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?voeunblck\\.com\\/e\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?voeunblk\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?voeunblk\\.com\\/e\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?audaciousdefaulthouse\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?audaciousdefaulthouse\\.com\\/e\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?launchreliantcleaverriver\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?launchreliantcleaverriver\\.com\\/e\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?reputationsheriffkennethsand\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?reputationsheriffkennethsand\\.com\\/e\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?fittingcentermondaysunday\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?fittingcentermondaysunday\\.com\\/e\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?housecardsummerbutton\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?housecardsummerbutton\\.com\\/e\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?fraudclatterflyingcar\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?fraudclatterflyingcar\\.com\\/e\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?bigclatterhomesguideservice\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?bigclatterhomesguideservice\\.com\\/e\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?uptodatefinishconferenceroom\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?uptodatefinishconferenceroom\\.com\\/e\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?20demidistance9elongations\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?20demidistance9elongations\\.com\\/e\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?un-block-voe\\.net\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?un-block-voe\\.net\\/e\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?vivo\\.(sx|st)\\/[0-9a-z]{10}",
        "(http|https):\\/\\/(\\w+\\.)?vivo\\.(sx|st)\\/embed\\/[0-9a-z]{10}",
        "(http|https):\\/\\/(\\w+\\.)?wdupload\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?world-files\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?wipfiles\\.net\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?worldbytez\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?wushare\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?xubster\\.com\\/[0-9a-z]{12}",
        "(http|https):\\/\\/(\\w+\\.)?youporn\\.com\\/watch\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?(yunfile|filemarkets|needisk|5xpan|dix3|dfpan|pwpan|tadown)\\.com\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?(dl-protecte|dl-protect1|protect-lien)\\.(com|co)\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?wlnk\\.ec\\/[0-9a-z]{8}",
        "(http|https):\\/\\/(\\w+\\.)?ed-protect\\.org\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?adhit\\.me\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/www[0-9]+.zippyshare\\.com\\/([^( |\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)",
        "(http|https):\\/\\/(\\w+\\.)?[a-z0-9\\-]+\\.[a-z]+\\/link-([^( |&|\"|'|>|<|\\r\\n\\|\\r|\\n|:|$)]+)"
    ]
    static let domains: [String] = ["olgply.xyz"]

    func canHandle(url: URL) -> Bool {
        print("URL---- \(url)")
        for regex in regexs {
            print("URL---- \(url.absoluteString.matches(for: regex))")
            if url.absoluteString.matches(for: regex).count > 0 {
                return true
            }
        }
        return false
    }

    func getMediaURL(url: URL) async throws -> [Stream] {
        return [
            .init(Resolver: "RD", streamURL: .init(staticString: "https://29.stream.real-debrid.com/t/Q2U4X77UUANYA55/eng1/none/aac/full.m3u8"))]
//        let parameters = [
//            [
//                "key": "link",
//                "value": url.absoluteString,
//                "type": "text"
//            ]] as [[String: Any]]
//
//        let boundary = "Boundary-\(UUID().uuidString)"
//        var body = ""
//        for param in parameters {
//            if param["disabled"] != nil { continue }
//            let paramName = param["key"]!
//            body += "--\(boundary)\r\n"
//            body += "Content-Disposition:form-data; name=\"\(paramName)\""
//            if param["contentType"] != nil {
//                body += "\r\nContent-Type: \(param["contentType"] as! String)"
//            }
//            let paramType = param["type"] as! String
//            if paramType == "text" {
//                let paramValue = param["value"] as! String
//                body += "\r\n\r\n\(paramValue)\r\n"
//            } else {
//                let paramSrc = param["src"] as! String
//                let fileData = try NSData(contentsOfFile: paramSrc, options: []) as Data
//                let fileContent = String(data: fileData, encoding: .utf8)!
//                body += "; filename=\"\(paramSrc)\"\r\n"
//                + "Content-Type: \"content-type header\"\r\n\r\n\(fileContent)\r\n"
//            }
//        }
//        body += "--\(boundary)--\r\n";
//        let postData = body.data(using: .utf8)
//
//        let data = try await Utilities.requestData(
//            url: .init(staticString: "https://api.real-debrid.com/rest/1.0/unrestrict/link"),
//            httpMethod: "POST",
//            data: postData,
//            extraHeaders: [
//                "Authorization":"Bearer \(token)",
//                "Content-Type":"multipart/form-data; boundary=\(boundary)"
//            ]
//        )
//
//        let results = try JSONDecoder().decode(RDResult.self, from: data)
//        if results.streamable == 1 {
//            return [.init(Resolver: "RD", streamURL: "https://29.stream.real-debrid.com/t/Q2U4X77UUANYA55/eng1/none/aac/full.m3u8")]
//        } else {
//            return []
//        }
    }

}

struct RDResult: Codable, Equatable {
    let id: String
    let filename: String
    let filesize: Int
    let host: String
    let download: URL
    let streamable: Int
}
