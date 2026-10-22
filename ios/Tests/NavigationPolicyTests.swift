import XCTest
@testable import Tonari

final class NavigationPolicyTests: XCTestCase {
    func testTrustOnlyExactHTTPSOrigin() {
        XCTAssertTrue(NavigationPolicy.isAppURL(NavigationPolicy.home))
        XCTAssertTrue(NavigationPolicy.isAppURL(URL(string: NavigationPolicy.home.absoluteString + ":443/api/me")!))
        for text in ["http://tonari-125374794305.asia-northeast1.run.app", "https://tonari-125374794305.asia-northeast1.run.app.evil.test", "https://user@tonari-125374794305.asia-northeast1.run.app", "https://tonari-125374794305.asia-northeast1.run.app:444", "http://127.0.0.1:8765", "javascript:alert(1)", "data:text/html,test"] {
            XCTAssertFalse(NavigationPolicy.isAppURL(URL(string: text)!), text)
        }
    }
    func testDownloadsKeepOriginBoundary() {
        XCTAssertTrue(NavigationPolicy.isDownloadURL(URL(string: "blob:" + NavigationPolicy.home.absoluteString + "/123")!))
        XCTAssertFalse(NavigationPolicy.isDownloadURL(URL(string: "blob:https://example.com/123")!))
        XCTAssertFalse(NavigationPolicy.isDownloadURL(URL(string: "file:///secret")!))
        XCTAssertFalse(NavigationPolicy.isDownloadURL(URL(string: "data:audio/mp4,123")!))
    }
    func testExternalLinksCannotOpenScriptOrLocalFiles() {
        for text in ["https://maps.google.com/", "tel:0312345678", "mailto:hello@example.com", "maps://?q=hospital"] {
            XCTAssertTrue(NavigationPolicy.canOpenExternally(URL(string: text)!))
        }
        for text in ["http://example.com", "javascript:alert(1)", "file:///secret", "itms-services://example.com", "https://user:pass@example.com"] {
            XCTAssertFalse(NavigationPolicy.canOpenExternally(URL(string: text)!))
        }
    }
    func testExportFilenameCannotEscapeTemporaryDirectory() {
        XCTAssertEqual(NavigationPolicy.safeFilename("../../recording.m4a"), "recording.m4a")
        XCTAssertEqual(NavigationPolicy.safeFilename("C:\\private\\recording.m4a"), "recording.m4a")
        XCTAssertEqual(NavigationPolicy.safeFilename(".."), "tonari-recording.m4a")
        XCTAssertFalse(NavigationPolicy.safeFilename("file\nname.m4a").contains("\n"))
    }
}
