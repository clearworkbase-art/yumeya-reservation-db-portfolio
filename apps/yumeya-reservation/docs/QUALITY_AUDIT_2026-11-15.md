# 夢屋旅館 v2 品質監査（2026-11-15）

## 対象と前提

- ブランチ: `feature/yumeya-db-v2`
- 対象: `apps/yumeya-reservation/`
- 監査はローカル作業ツリーに対して実施。Commit、Push、Merge、main変更は行っていない。
- DBパスワードは読み出し・表示・保存していない。

## Git・ファイル監査

| 項目 | 判定 | 根拠 |
|---|---|---|
| 作業ブランチ | 確認済み | `feature/yumeya-db-v2` |
| mainとの差分 | 確認済み | featureはmainより1コミット先行。v2の多数の変更は未コミットの作業ツリー |
| headerブランチとの関係 | 確認済み | `feature/yumeya-header-compact` と同一コミットを指す |
| 未追跡マーカー | 要注意 | リポジトリ直下の `h -u origin main` は未追跡のまま保護。変更・削除していない |
| ビルド成果物 | 除外対象 | `target/` とWARは `.gitignore` 対象 |
| 秘密情報 | 現時点で混入なし | コードは環境変数参照。パスワード値は作業報告・資料に記載していない |
| 形式設定 | 確認済み | `.editorconfig` のPowerShell設定はUTF-8 BOM、CRLF |

## DB・Java品質監査

| 観点 | 判定 | 根拠 |
|---|---|---|
| ER構造 | 確認済み | `db/01_schema.sql:5-29`、`docs/DB_DESIGN.md`。rooms 1対多 reservations |
| PK/FK/UNIQUE/CHECK | 確認済み | `db/01_schema.sql:6-8,12-24` の各制約 |
| 予約期間の重複防止 | 確認済み | `db/01_schema.sql:25-28` の `EXCLUDE USING gist`。Smokeでも重複拒否を確認 |
| 同時実行時の整合性 | 設計上確認済み | アプリの入力検証ではなくDB排他制約で競合を拒否。高負荷試験は未実施 |
| SQLインジェクション | 確認済み | `ReservationRepository.java:14-30,34-70,73-80` で値をPreparedStatementにバインド |
| INSERT/SELECT/UPDATE | 確認済み | `ReservationRepository.java:14-80` の `insert`、`find`、`search`、`cancel` |
| JDBC例外処理 | 確認済み | `DbConnection.java:11-27` が環境変数・URL・ドライバーを検証。`CompleteServlet.java:42-45` は利用者向け503を返す |
| ロールバック | 未検証 | 単一SQLは原子性で完結。複数SQLの明示的rollbackは未実装 |
| インデックス | 確認済み | `db/01_schema.sql:37-38` の作成日時・客室状態インデックス。25-28にGiST排他制約あり |
| DB最小権限 | 未検証 | 接続成功は確認したが、information_schema等での権限棚卸しは未実施 |
| 取消履歴 | 確認済み | `ReservationRepository.java:73-80` はDELETEではなくstatus/cancelled_at更新。Smoke後のテスト行をCANCELLEDで保持 |
| 管理画面制限 | 部分確認 | `LocalOnlyFilter.java:13-24` と `LocalAdminAccess.java:8-14` でloopback限定。認証・本番認可ではない |
| CSRF/セッション | 確認済み | `CompleteServlet.java:21-23` などPOSTでCSRFトークンを検証、`WEB-INF/web.xml:4-7`でHttpOnly・COOKIE追跡を設定 |
| XSS | 部分確認 | 入力値検証と管理画面の出力エスケープを確認。JSP全画面のブラウザ検証は未実施 |
| 機密情報露出 | 確認済み | 503画面は一般メッセージ、パスワードはログ出力しない。ログの詳細例外運用は今後整理 |

## 重大度順の問題

1. **高: 画像の公開権利が未確認。** Getty名・透かし画像を含み、公開前に除外または正規ライセンス確認が必要。
2. **高: 管理画面は認証ではなくloopback制限のみ。** 外部公開・本番利用は禁止。
3. **中: DBユーザーの最小権限を未検証。** DDL実行者とアプリ実行者を分離し、権限一覧を記録する必要がある。
4. **中: 境界日付、DB停止時503、スマホ表示、手動SQL/EXPLAINは未実施。** 成功済みと記載してはいけない。
5. **低: v2変更は未コミット。** 反映前に候補ファイルを選別し、`h -u origin main` と生成物を除外する必要がある。

追加監査で、専用一時DB向けの非破壊テストSQL（`db/04_tempdb_validation.sql`）と、DB権限を変更せず確認するPowerShell（`scripts/yumeya-db-permissions-audit.ps1`）を追加した。いずれも今回の実DBでは未実行である。

## 今回の実機検証

- Maven `clean package`: 成功
- JUnit: 7/7成功
- PostgreSQL接続: 成功。`rooms=3`、予約件数を確認
- HTTP Smoke: 登録・一覧・重複拒否・取消に成功
- テスト予約ID 1: `CANCELLED` として保持
- Tomcat配備: v2 WARへ更新済み。v1バックアップは別フォルダで保護

## 公開判断

**CONDITIONAL GO**。DBデモとしての説明力とローカル検証は十分ですが、画像権利確認、最小権限確認、未実施テスト、未コミット差分の整理が完了するまで、公開サイトやmainへの反映は承認しません。
