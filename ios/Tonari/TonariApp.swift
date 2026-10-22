import SwiftUI

@main
struct TonariApp: App {
    var body: some Scene {
        WindowGroup { TonariView().preferredColorScheme(.light) }
    }
}

struct TonariView: View {
    @StateObject private var browser = BrowserModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Color(red: 244/255, green: 248/255, blue: 252/255).ignoresSafeArea()
            BrowserView(model: browser)
            if browser.loading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("となりを開いています").font(.headline)
                }
                .padding(28)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                .accessibilityIdentifier("loading")
            }
            if let message = browser.failure {
                VStack(spacing: 20) {
                    Image(systemName: "wifi.exclamationmark").font(.largeTitle)
                    Text("となりに接続できませんでした").font(.title3.bold())
                    Text(message).multilineTextAlignment(.center)
                    Button("もう一度接続する") { browser.retry() }
                        .buttonStyle(.borderedProminent)
                        .frame(minHeight: 44)
                        .accessibilityIdentifier("retry")
                    Text("保存した記録は削除されません。\n通信環境を確認してから、もう一度お試しください。")
                        .font(.footnote).multilineTextAlignment(.center)
                }
                .padding(28).frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 244/255, green: 248/255, blue: 252/255))
                .accessibilityIdentifier("connection-error")
            }
            // Hide health information in the app switcher. Do not reload on resume.
            if scenePhase != .active {
                Color(red: 244/255, green: 248/255, blue: 252/255).ignoresSafeArea()
                Text("となり").font(.largeTitle.bold()).accessibilityIdentifier("privacy-cover")
            }
        }
        .tint(Color(red: 24/255, green: 95/255, blue: 165/255))
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { browser.stopCapture() }
        }
    }
}
