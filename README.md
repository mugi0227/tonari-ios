# となり iOS（ビルド用）

TonariのiPhoneアプリを、GitHub ActionsのmacOSでビルドしてTestFlightへ送るためのリポジトリです。
公開リポジトリのmacOSランナーを使うので、ビルドに費用はかかりません。

**アプリのソースはここにはありません。**
ソースは非公開のリポジトリにあります（既定は`mugi0227/Tonari`。リポジトリ変数`APP_SOURCE_REPO`で変えられます）。
ワークフローは、実行時に読み取り専用のデプロイキーでソースを取得してビルドします。
このリポジトリに公開されるのは、次のものだけです。
- ワークフローの定義
- ビルドログ（ファイル名とテスト名）
- 架空データの画面のスクリーンショット

IPA（中に画面とロジックが入っている）は、成果物として残しません。

## 使い方

GitHub → Actions で手動実行します。`source_ref`には、非公開リポジトリのブランチかコミットを指定します。

| ワークフロー | すること |
|---|---|
| `Tonari iOS simulator checks` | ロジックのテスト、Web画面の同梱、シミュレーターでのテストとスクリーンショット |
| `Tonari iOS build` | 上のチェックが通った同じコミットを署名し、TestFlightへアップロード |

## 必要な設定（Settings → Secrets and variables → Actions）

| 名前 | 種類 | 内容 |
|---|---|---|
| `APP_SOURCE_DEPLOY_KEY` | Secret | 非公開リポジトリの読み取り専用デプロイキー（秘密鍵） |
| `GOOGLE_SERVICE_INFO_PLIST` | Secret | FirebaseのiOSアプリ設定（base64） |
| `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8`, `TONARI_SIGNING_P12`, `TONARI_SIGNING_PASSWORD` | Secret | 署名とアップロード（設定済み） |
| `TONARI_TESTFLIGHT_UPLOAD` | Variable | `true`でTestFlightへアップロード（設定済み） |

デプロイキーの作り方（Windows の PowerShell）：

```powershell
ssh-keygen -t ed25519 -C "tonari-ios build" -f tonari_deploy
```

パスフレーズを聞かれたら、何も入れずにEnterを2回押します。

1. `tonari_deploy.pub`の中身を、非公開リポジトリ → Settings → Deploy keys → Add deploy key に貼る（「Allow write access」は付けない）
2. `tonari_deploy`の中身を、このリポジトリの Secret `APP_SOURCE_DEPLOY_KEY` に貼る
3. 2つのファイルは削除する

Secretsはフォークからのプルリクエストでは使えません。また、ワークフローを実行できるのは書き込み権限のある人だけです。

旧版（Cloud Runの画面を表示するだけの外枠、0.1.0）のソースはこのリポジトリの履歴に残っています。
iPhoneへの入れ方は[docs/testflight-readiness.md](docs/testflight-readiness.md)を参照してください。
