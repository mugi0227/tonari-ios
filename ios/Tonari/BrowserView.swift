import SwiftUI
import WebKit

@MainActor
final class BrowserModel: ObservableObject {
    @Published var loading = true
    @Published var failure: String?
    weak var controller: BrowserController?
    func retry() { controller?.loadHome() }
    func stopCapture() { controller?.webView.setMicrophoneCaptureState(.none, completionHandler: {}) }
}

struct BrowserView: UIViewControllerRepresentable {
    @ObservedObject var model: BrowserModel
    func makeUIViewController(context: Context) -> BrowserController { BrowserController(model: model) }
    func updateUIViewController(_ uiViewController: BrowserController, context: Context) {}
}

@MainActor
final class BrowserController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate {
    let model: BrowserModel
    let webView: WKWebView
    private var microphoneObserver: NSKeyValueObservation?
    private var loadingTimeout: Task<Void, Never>?
    private var downloadPaths: [ObjectIdentifier: URL] = [:]
    private var downloads: [ObjectIdentifier: WKDownload] = [:]
    private var exportQueue: [URL] = []
    private var exportDirectory: URL?

    init(model: BrowserModel) {
        self.model = model
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        webView = WKWebView(frame: .zero, configuration: config)
        super.init(nibName: nil, bundle: nil)
        model.controller = self
    }
    required init?(coder: NSCoder) { fatalError("Use init(model:)") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 244/255, green: 248/255, blue: 252/255, alpha: 1)
        webView.backgroundColor = view.backgroundColor
        webView.isOpaque = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.accessibilityIdentifier = "tonari-web"
        view.addSubview(webView)
        // The page has its own fixed header/tab bar. Keep both inside safe areas.
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        microphoneObserver = webView.observe(\.microphoneCaptureState, options: [.new]) { web, _ in
            Task { @MainActor in UIApplication.shared.isIdleTimerDisabled = web.microphoneCaptureState != .none }
        }
        loadHome()
    }

    func loadHome() {
        model.loading = true
        model.failure = nil
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-offline") {
            showFailure("インターネットへの接続を確認してください。")
            return
        }
        if ProcessInfo.processInfo.arguments.contains("--ui-fixture"),
           let file = Bundle.main.url(forResource: "fixture", withExtension: "html"),
           let html = try? String(contentsOf: file, encoding: .utf8) {
            webView.loadHTMLString(html, baseURL: NavigationPolicy.home)
            return
        }
        #endif
        loadingTimeout?.cancel()
        loadingTimeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(45))
            guard !Task.isCancelled, let self, self.model.loading else { return }
            self.webView.stopLoading()
            self.showFailure("接続に時間がかかっています。時間をおいてからお試しください。")
        }
        var request = URLRequest(url: NavigationPolicy.home)
        request.timeoutInterval = 40
        webView.load(request)
    }

    func showFailure(_ message: String) {
        loadingTimeout?.cancel()
        model.loading = false
        model.failure = message
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loadingTimeout?.cancel()
        model.loading = false
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { fail(error) }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { fail(error) }
    private func fail(_ error: Error) {
        // Cancellation can be an intentional external link or a download.
        guard (error as NSError).code != NSURLErrorCancelled else { return }
        showFailure("インターネットへの接続を確認してください。")
    }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        UIApplication.shared.isIdleTimerDisabled = false
        showFailure("画面の処理が終了しました。録音中だった場合は、接続し直して保存済みの音声を確認してください。")
    }
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = action.request.url else { decisionHandler(.cancel); return }
        if action.shouldPerformDownload && NavigationPolicy.isDownloadURL(url) {
            decisionHandler(.download); return
        }
        // Ignore initial about:blank used by WebKit itself (never allow scripts/data URLs).
        if url.absoluteString == "about:blank" { decisionHandler(.allow); return }
        if NavigationPolicy.isAppURL(url) {
            if action.targetFrame == nil {
                webView.load(action.request)
                decisionHandler(.cancel)
            } else { decisionHandler(.allow) }
            return
        }
        if action.navigationType == .linkActivated && NavigationPolicy.canOpenExternally(url) {
            UIApplication.shared.open(url)
        }
        decisionHandler(.cancel)
    }
    func webView(_ webView: WKWebView, decidePolicyFor response: WKNavigationResponse,
                 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if response.isForMainFrame, let http = response.response as? HTTPURLResponse, http.statusCode >= 400 {
            showFailure("サーバーに接続できませんでした。時間をおいてからお試しください。")
            decisionHandler(.cancel); return
        }
        decisionHandler(response.canShowMIMEType ? .allow : .download)
    }
    func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType,
                 decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        // Keep iOS/WebKit's permission prompt; never grant unseen permission requests.
        let trusted = origin.protocol == "https" && origin.host == NavigationPolicy.home.host &&
            (origin.port == 0 || origin.port == 443) && frame.isMainFrame &&
            frame.request.url.map(NavigationPolicy.isAppURL) == true
        decisionHandler(trusted ? .prompt : .deny)
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: "となり", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "閉じる", style: .default) { _ in completionHandler() })
        present(alert, animated: true)
    }
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "となり", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "続ける", style: .default) { _ in completionHandler(true) })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) { track(download) }
    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) { track(download) }
    private func track(_ download: WKDownload) {
        downloads[ObjectIdentifier(download)] = download
        download.delegate = self
    }
    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse,
                  suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        do {
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent("TonariExports", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                attributes: [.protectionKey: FileProtectionType.complete])
            exportDirectory = directory
            let unique = directory.appendingPathComponent(UUID().uuidString, isDirectory: true)
            try FileManager.default.createDirectory(at: unique, withIntermediateDirectories: true,
                attributes: [.protectionKey: FileProtectionType.complete])
            let destination = unique.appendingPathComponent(NavigationPolicy.safeFilename(suggestedFilename))
            downloadPaths[ObjectIdentifier(download)] = destination
            completionHandler(destination)
        } catch { completionHandler(nil) }
    }
    func downloadDidFinish(_ download: WKDownload) {
        let id = ObjectIdentifier(download)
        if let url = downloadPaths.removeValue(forKey: id) { exportQueue.append(url) }
        downloads.removeValue(forKey: id)
        showNextExport()
    }
    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        let id = ObjectIdentifier(download)
        if let url = downloadPaths.removeValue(forKey: id) { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        downloads.removeValue(forKey: id)
        let alert = UIAlertController(title: "録音を書き出せませんでした", message: "録音は端末内に残っています。もう一度お試しください。", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "閉じる", style: .default) { [weak self] _ in self?.showNextExport() })
        if presentedViewController == nil { present(alert, animated: true) }
    }
    private func showNextExport() {
        guard downloads.isEmpty, !exportQueue.isEmpty, presentedViewController == nil else { return }
        let files = exportQueue
        exportQueue = []
        let sheet = UIActivityViewController(activityItems: files, applicationActivities: nil)
        sheet.popoverPresentationController?.sourceView = view
        sheet.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        sheet.completionWithItemsHandler = { [weak self] _, _, _, _ in
            files.forEach { try? FileManager.default.removeItem(at: $0.deletingLastPathComponent()) }
            Task { @MainActor in
                // UIKit may still be dismissing the previous activity controller.
                try? await Task.sleep(for: .milliseconds(500))
                self?.showNextExport()
            }
        }
        present(sheet, animated: true)
    }
}
