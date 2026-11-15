# Windows 11 / VS Code / Tomcat9 / PostgreSQL の導入・確認

このv2は開発用のローカルDBデモです。Netlifyでは動きません。v1は残したまま検証してください。

## 1. PostgreSQLの確認

- インストール未済なら公式 https://www.postgresql.org/download/windows/ を参照。ローカルPC用のみで十分です。
- 5432番をインターネットに公開しないでください。必ずlocalhostから接続します。
- PostgreSQLの管理ツール（psqlまたはpgAdmin）で、専用DB `yumeya_portfolio` と専用ユーザー `yumeya_app` を使用します。
- テーブル作成時に `btree_gist` 拡張の追加権限が必要な場合、DB管理者で初期化してからアプリ用ユーザーへ必要最小限の権限を付与します。
- `db/01_schema.sql` を `yumeya_portfolio` に実行します。既存の本番DB・別アプリDBには絶対に実行しないでください。

### 初期SQL例（管理ユーザーで実行、パスワードは自分で設定）

```sql
CREATE ROLE yumeya_app LOGIN PASSWORD 'ここは自分で決めた長いパスワード';
CREATE DATABASE yumeya_portfolio OWNER yumeya_app;
```

作成済みの専用DBへ接続し `db/01_schema.sql` を実行。拡張機能の権限問題が起きたらメッセージを共有してください。
パスワードの文字列はGitHubに書かず、実行時の環境変数で渡します。

## 2. 環境変数（新しいPowerShellで毎回セット可能）

```powershell
$env:YUMEYA_JDBC_URL = 'jdbc:postgresql://127.0.0.1:5432/yumeya_portfolio'
$env:YUMEYA_DB_USER = 'yumeya_app'
$securePassword = Read-Host 'デモDBパスワード' -AsSecureString
$pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
try { $env:YUMEYA_DB_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer) }
finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer) }
```

**重要:** パスワードをコマンド文字列やGitHubに書かないでください。環境変数内では値が平文になります。変数は `catalina.bat run` を実行する **同じターミナル** で設定してください。
既にTomcatが起動していたら `Ctrl+C` で止め、変数設定後に再起動します。

## 3. 1コマンドの開発操作

リポジトリのルートで、`feature/yumeya-db-v2`などの作業ブランチから実行します。`main`/`master`では安全のため停止します。

```powershell
# ビルド＋JUnit＋WAR生成＋既存配備のバックアップ＋v2配置（Tomcatは起動しない）
.\scripts\yumeya-local.ps1 -Action Deploy

# 上記に加えて、DBパスワードを端末で安全に入力し、Tomcatを起動
.\scripts\yumeya-local.ps1 -Action Up

# Tomcat起動中に修正版WARだけを安全に再配備（TomcatのDB環境変数を維持）
.\scripts\yumeya-local.ps1 -Action HotDeploy

# DB接続・rooms/reservations件数の確認
.\scripts\yumeya-local.ps1 -Action DbCheck

# 登録・一覧・重複拒否・取消のHTTPスモークテスト
.\scripts\yumeya-local.ps1 -Action Smoke

# 停止・再起動
.\scripts\yumeya-local.ps1 -Action Stop
.\scripts\yumeya-local.ps1 -Action Restart
```

パスワードは現在のPowerShellプロセスにだけ設定し、ファイル・Git・ログには保存しません。別のPowerShellやVS Codeターミナルには自動継承されないため、`Up`/`DbCheck`/`Smoke`で必要時に端末入力します。

Windows PowerShellのExecutionPolicyで`.ps1`の直接実行が拒否される場合は、Windows全体の設定を変更せず、実行プロセスだけにBypassを指定します。

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\yumeya-local.ps1 -Action Up
```

このプロジェクトの`.ps1`はWindows PowerShell 5.1で日本語を正しく読むため、UTF-8 BOM付きで保存します。VS Codeの保存設定でも`UTF-8 with BOM`を選択してください。

## 4. ビルドとWAR配置

リポジトリのルートで:

```powershell
mvn -f .\apps\yumeya-reservation\pom.xml clean package
```

`scripts\build-deploy.ps1`は互換用の安全なラッパーです。内部でビルド・テストを実行し、既存WARと展開済みフォルダを日時付きバックアップへ移してから配置します。
Tomcat9のパスが異なる場合は引数 `-TomcatHome '実際の場所'` を指定します。

## 5. 起動・画面

```powershell
$env:CATALINA_HOME = '<Tomcat installation directory>'
& "$env:CATALINA_HOME\bin\catalina.bat" run
```

ブラウザに `http://127.0.0.1:8080/yumeya-reservation/` を手入力。
フォーム: `/reservation`。管理一覧: `/admin/reservations`。
URLに `**` や `?utm_source=...` が入らないようにしてください。

## 6. v1への復旧

`yumeya-reservation-backups`内の最新バックアップを使う場合:

```powershell
.\scripts\yumeya-local.ps1 -Action RestoreV1
```

特定のバックアップを指定する場合は`-BackupPath`を追加します。復旧時も現在の配備を別名へ退避し、削除せず保全します。

## 7. リリース禁止・未確認事項

- 今回のDBデモには本番用の認証・認可・接続プール・監視などがありません
- `LocalOnlyFilter` はローカル以外からのDBページアクセスを拒否しますが、公開の代替にはなりません
- 画像・写真の権利関係も別途確認が必要です
- 機能はローカルで検証してからポートフォリオに載せてください

## 8. DB権限の読み取り専用監査

権限を変更せずに確認する場合は、リポジトリルートで次を実行します。パスワードは端末プロンプトにだけ入力し、結果は保存されません。

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\yumeya-db-permissions-audit.ps1
```

この監査は、ロール属性、DBのCONNECT/CREATE/TEMPORARY、スキーマUSAGE/CREATE、テーブルごとのSELECT/INSERT/UPDATE/DELETE等、シーケンス権限、ロール所属だけをSELECTで確認します。`GRANT`、`ALTER ROLE`、`DROP`、DB初期化は実行しません。
