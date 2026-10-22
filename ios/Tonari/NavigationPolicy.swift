import Foundation

enum NavigationPolicy {
    static let home = URL(string: "https://tonari-125374794305.asia-northeast1.run.app")!
    static func isAppURL(_ url: URL) -> Bool {
        url.scheme?.lowercased() == "https" && url.host?.lowercased() == home.host &&
        (url.port == nil || url.port == 443) && url.user == nil && url.password == nil
    }
    static func isDownloadURL(_ url: URL) -> Bool {
        if isAppURL(url) { return true }
        guard url.scheme == "blob", let origin = URL(string: String(url.absoluteString.dropFirst(5))) else { return false }
        return isAppURL(origin)
    }
    static func canOpenExternally(_ url: URL) -> Bool {
        guard url.user == nil, url.password == nil else { return false }
        return ["https", "mailto", "tel", "maps"].contains(url.scheme?.lowercased() ?? "")
    }
    static func safeFilename(_ filename: String) -> String {
        let name = filename.replacingOccurrences(of: "\\", with: "/").split(separator: "/").last.map(String.init) ?? ""
        let clean = name.unicodeScalars.filter { !CharacterSet.controlCharacters.contains($0) }
        let result = String(String.UnicodeScalarView(clean)).prefix(160)
        return result.isEmpty || result == "." || result == ".." ? "tonari-recording.m4a" : String(result)
    }
}
