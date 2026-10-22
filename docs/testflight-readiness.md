# となり iOSの準備状況

iPhone用アプリと署名済みIPAを作成し、単体4件・画面操作4件の検査が成功しました。
**TestFlight配布はAppleの新規アプリ登録待ちです。まだインストールできる状態ではありません。**
ハッカソン提出済みのTonari本体のmainと審査用公開版を保持し、iOS開発は別ブランチで行っています。

## アプリと検証

SwiftUIとWKWebViewで現在のクラウド版を使います。
インストール後はPCの起動やUSB接続が不要で、インターネット接続が必要です。
メール認証とサーバーの家族の記録を利用できます。
Safariの端末内録音は自動移行されません。
録音は画面を開いたまま使い、共有画面からファイルに保存できます。

- iOS 17以降、バージョン0.1.0/build 2。
- [Xcode 26.3の実機向け署名済みビルド](https://github.com/mugi0227/tonari-ios/actions/runs/39707086571)が成功。署名・App ID・版・ARM64・配布プロファイル・ReleaseでのDebug機能無効化を照合しました。
- [Xcode 16.4 / iOS 18.5の検査](https://github.com/mugi0227/tonari-ios/actions/runs/39708829012)は全8件が成功。URL制限、保存名、メモと録音データの再起動後の保持、確認ダイアログ、録音の共有、通信失敗と再接続を検証しました。
- 縦横の画像を目視確認しました。実iPhoneのログイン・マイク・写真・現在地・長時間録音はインストール後の確認が必要です。

[起動画面](screenshots/landing.png) / [横向きの起動](screenshots/landing-landscape.png) / [録音の共有](screenshots/recording-export.png) / [横向きの再接続](screenshots/offline-landscape.png)

画面はログイン前または架空のテスト用データです。
本番へのログイン、ゲスト作成、AI利用、既存記録の変更は行っていません。

## 次の操作

[App Store Connect](https://appstoreconnect.apple.com/apps)へログインし、新規アプリを登録します。
Bundle IDは登録済みです。
新規レコードの作成には[AppleのWeb画面](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/)が必要です。

| 項目 | 入力する内容 |
|---|---|
| プラットフォーム | iOS |
| 名前 | となり - 診察の相棒 |
| プライマリ言語 | 日本語 |
| Bundle ID | jp.mugilab.tonari |
| SKU | tonari-ios-20261022 |
| ユーザーアクセス | フルアクセス（既存の開発チーム内） |

登録後、アプリIDと既存ビルドを照合し、TestFlightへの送信、Appleの処理完了、本人用の内部グループへの配布を行います。
その後はiPhoneのTestFlightからインストールできます。
App Storeの一般公開と外部ベータ審査には提出しません。

この公開リポジトリは、本人の承認を受けた新規のiOS外枠、検証、ビルド処理とその説明だけです。
Tonari本体の非公開Web/APIソースや認証情報は含みません。
