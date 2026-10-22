import XCTest

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
        let filename = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "tonari-test")).firstMatch
        let exported = filename.waitForExistence(timeout: 12)
        attach(app, "recording-export")
        XCTAssertTrue(exported, app.debugDescription)
    }
    func testOfflineRetryAndLandscapeLayout() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-offline"]
        app.launch()
        XCTAssertTrue(app.buttons["retry"].waitForExistence(timeout: 10))
        app.buttons["retry"].tap()
        XCTAssertTrue(app.buttons["retry"].exists)
        XCUIDevice.shared.orientation = .landscapeLeft
        attach(app, "offline-landscape")
        XCUIDevice.shared.orientation = .portrait
    }
    func testLiveLandingReadOnly() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP"]
        app.launch()
        // No sign-in, guest creation, AI request, or record mutations.
        XCTAssertTrue(app.buttons["ゲストで見る（架空のデータ）"].waitForExistence(timeout: 55))
        attach(app, "live-landing")
        XCUIDevice.shared.orientation = .landscapeLeft
        attach(app, "live-landing-landscape")
        XCUIDevice.shared.orientation = .portrait
    }
    private func attach(_ app: XCUIApplication, _ name: String) {
        let item = XCTAttachment(screenshot: app.screenshot())
        item.name = name; item.lifetime = .keepAlways; add(item)
    }
}
