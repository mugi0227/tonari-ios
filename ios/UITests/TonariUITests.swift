import XCTest
import UIKit

final class TonariUITests: XCTestCase {
    private func fixture() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-fixture", "-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP"]
        app.launch()
        XCTAssertTrue(app.staticTexts["となりの動作確認"].waitForExistence(timeout: 20))
        return app
    }
    func testLocalStorageSurvivesAppRelaunchAndConfirmIsNative() {
        let app = fixture()
        let memo = app.textFields["保存するメモ"]
        memo.tap()
        if let value = memo.value as? String, !value.isEmpty {
            memo.press(forDuration: 1)
            if app.menuItems["すべてを選択"].exists { app.menuItems["すべてを選択"].tap() }
        }
        // Use a fresh value and compare the exact persisted field on relaunch.
        let text = "架空の確認メモ"
        memo.typeText(text)
        let expected = memo.value as? String
        app.buttons["端末に保存"].tap()
        XCTAssertTrue(app.staticTexts["保存しました"].waitForExistence(timeout: 5))
        app.buttons["確認用の録音を保存"].tap()
        XCTAssertTrue(app.staticTexts["録音の保存を確認しました"].waitForExistence(timeout: 5))
        app.terminate(); app.launch()
        XCTAssertTrue(app.textFields["保存するメモ"].waitForExistence(timeout: 15))
        XCTAssertEqual(app.textFields["保存するメモ"].value as? String, expected)
        XCTAssertTrue(app.staticTexts["録音の保存を確認しました"].waitForExistence(timeout: 5))
        app.buttons["確認ダイアログ"].tap()
        XCTAssertTrue(app.alerts["となり"].waitForExistence(timeout: 5))
        app.alerts.buttons["キャンセル"].tap()
        XCTAssertTrue(app.staticTexts["取り消しました"].waitForExistence(timeout: 5))
        app.buttons["確認ダイアログ"].tap()
        app.alerts.buttons["続ける"].tap()
        XCTAssertTrue(app.staticTexts["確認して続けました"].waitForExistence(timeout: 5))
        attach(app, "fixture-portrait")
    }
    func testBlobRecordingExportOpensNativeShareSheet() {
        let app = fixture()
        app.buttons["録音を書き出す"].tap()
        // UIActivityViewController exposes the system share sheet, including Copy.
        let sheet = app.otherElements["ActivityListView"]
        let exported = sheet.waitForExistence(timeout: 12)
        attach(app, "recording-export")
        XCTAssertTrue(exported, app.debugDescription)
        // iOS exposes the share-sheet filename as Other, rather than StaticText.
        let filename = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "tonari-test")).firstMatch
        XCTAssertTrue(filename.waitForExistence(timeout: 5))
        XCTAssertTrue(app.cells["Save to Files"].waitForExistence(timeout: 5) || app.cells["ファイルに保存"].exists)
    }
    func testOfflineRetryAndLandscapeLayout() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-offline"]
        app.launch()
        // SwiftUI can propagate a parent accessibility identifier to children.
        let retry = app.buttons["もう一度接続する"]
        XCTAssertTrue(retry.waitForExistence(timeout: 10))
        retry.tap()
        XCTAssertTrue(retry.exists)
        rotate(.landscapeLeft, app: app, landscape: true)
        attach(app, "offline-landscape")
        rotate(.portrait, app: app, landscape: false)
    }
    func testLiveLandingReadOnly() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP"]
        app.launch()
        // No sign-in, guest creation, AI request, or record mutations.
        XCTAssertTrue(app.buttons["ゲストで見る（架空のデータ）"].waitForExistence(timeout: 55))
        attach(app, "live-landing")
        rotate(.landscapeLeft, app: app, landscape: true)
        attach(app, "live-landing-landscape")
        rotate(.portrait, app: app, landscape: false)
    }
    private func rotate(_ orientation: UIDeviceOrientation, app: XCUIApplication, landscape: Bool) {
        XCUIDevice.shared.orientation = orientation
        var lastFrame = CGRect.zero
        var stableSince = Date()
        let settled = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let frame = app.frame
            if frame != lastFrame { lastFrame = frame; stableSince = Date() }
            return (frame.width > frame.height) == landscape && Date().timeIntervalSince(stableSince) >= 1
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [settled], timeout: 10), .completed)
    }
    private func attach(_ app: XCUIApplication, _ name: String) {
        let item = XCTAttachment(screenshot: app.screenshot())
        item.name = name; item.lifetime = .keepAlways; add(item)
    }
}
