# となり iOS

TonariのiOS用外枠です。
SwiftUIとWKWebViewで既存のクラウドアプリを表示します。
インストール後に開発PCは不要で、インターネット接続が必要です。

このリポジトリにはiOSコード、テスト、Macでのビルドと署名の工程だけを含めます。
Web/APIの非公開ソース、ハッカソン提出物、認証情報、利用者の記録は含めません。
ハッカソンの提出済みリポジトリや審査用デプロイを変更する権限はありません。

## 構成

- `ios/`: iOS 17以降。現在のメール認証、家族の記録、診察準備、録音の画面を表示します。
- 録音ファイルはiOSの共有画面から保存できます。録音中は画面を開いて使います。
- Safariの端末内録音は自動移行されません。
- 外部の病院や地図へのリンクは標準アプリで開きます。
- 通信失敗時は手動で再接続します。バックグラウンド録音とPush通知は含みません。

## ビルド

GitHub ActionsでXcodeGen生成、Simulator検査、配布署名済みIPAを作ります。
3つのworkflowはすべて手動実行です。
`ios-tests.yml` はXcode 16.4 / iOS 18.5で検査し、`ios-device.yml` はXcode 26.3で実機用IPAを書き出します。
`ios-testflight.yml` は同じiOSソースのSimulator成功を確認してから配布用ビルドを行います。
既存のApple Distribution証明書を再利用し、新規発行や失効はしません。
署名情報はGitHub Actions Secretsに保存します。
Apple側のアプリ登録後に `TONARI_TESTFLIGHT_UPLOAD=true` を設定してアップロードします。
App Storeの一般公開には提出しません。

2026/10/26に **0.1.0 (7)をTestFlightへ配布しました**。
[配布ビルド](https://github.com/mugi0227/tonari-ios/actions/runs/40321246531)が成功し、Appleの処理完了と内部テスト中を確認しています。
本人のみの内部グループです。[iPhoneでのインストール手順](docs/testflight-readiness.md)を参照してください。
実iPhoneでのログイン・マイク・写真の確認はこれからです。

全画面を撮影した[追加検査](https://github.com/mugi0227/tonari-ios/actions/runs/39708829012)も8件成功しています。
画面画像は [docs/screenshots](docs/screenshots/) にあります。アプリ画面はログイン前または架空の確認用データ、配布状況の画面はアカウント情報を除いたものです。
