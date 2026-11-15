# PostgreSQL最小権限化設計

## 目的

DDLを担当するNOLOGINロール `yumeya_owner` と、Tomcatから接続する `yumeya_app` を分離します。アプリ実行ユーザーには、予約画面・一覧・取消に必要なDMLだけを与え、DB・スキーマ・テーブルの作成や削除を許可しません。

## Java実装から特定した必要権限

| 対象 | 必要権限 | 根拠 |
|---|---|---|
| `rooms` | SELECT | `ReservationRepository.search/find` のJOIN |
| `reservations` | SELECT | 一覧・登録後取得 |
| `reservations` | INSERT対象列 | `insert()` の登録 |
| `reservations` | UPDATE対象列 `status,cancelled_at` | `cancel()` の取消 |
| identity sequence | 付与しない | 通常のIDENTITY INSERTでは個別sequence権限を不要とする。直接`nextval()`はアプリから使わない |
| DB | CONNECT | JDBC接続 |
| schema | USAGE | `public`内の表参照 |
| CREATE/ALTER/DROP/TRUNCATE | 不要 | Javaコード・SQLにDDL/DML以外の管理操作なし |

## 移行SQL

`db/05_privilege_migration.sql` は次を行います。

1. `yumeya_owner` をNOLOGIN・非SUPERUSER等で作成
2. `yumeya_app`から`yumeya_owner`の継承を解除
3. `PUBLIC`と`yumeya_app`からDB/スキーマCREATEを剥奪
4. テーブル・シーケンス権限を一度REVOKE
5. 必要なSELECT/INSERT/限定UPDATEだけをGRANT。identity sequence権限は付与しない
6. DB、スキーマ、テーブル、identity sequenceの所有者を`yumeya_owner`へ移行

所有権変更は強い操作なので、`yumeya_portfolio`への適用には事前承認が必要です。

## `REASSIGN OWNED`を使わない理由

この移行では`REASSIGN OWNED`を実行しません。PostgreSQLのロールはクラスタ全体で共有され、`REASSIGN OWNED`は現在のDB内の所有オブジェクトだけでなく、ロールが所有する共有オブジェクト（DB・テーブルスペース）にも影響し得ます。既存の`yumeya_app`が他DBで所有するオブジェクトを巻き込まないため、対象DBの既知のテーブル・sequenceだけを`ALTER ... OWNER TO`で移行します。

`public`スキーマの現所有者が`pg_database_owner`である場合は、その標準関係を維持します。DB所有者を`yumeya_owner`へ移行すると、`pg_database_owner`の暗黙のメンバーとしてDB所有者が管理権限を持つため、スキーマ所有者を直接書き換える必要はありません。

## ロールバック

`db/06_privilege_rollback_template.sql` は雛形です。元の所有者を監査結果から確認し、プレースホルダーを置換してから使用します。自動で所有者を推測して戻す処理は入れていません。

## テストDBでの検証手順

本番相当の`yumeya_portfolio`では実行しません。

1. 管理者で空のテストDBを作成する
2. `01_schema.sql`をテストDBへ適用する
3. `05_privilege_migration.sql`のDB名をテストDB名へ置換し、`ALTER DATABASE`部分は対象DB以外（通常は`postgres`）へ接続して適用する
4. `yumeya_app`で接続し、予約登録・検索・重複拒否・取消を確認する
5. `CREATE TABLE`、`TRUNCATE`、`DROP TABLE`、`ALTER TABLE`、`CREATE SCHEMA`が拒否されることを確認する
6. `pg_roles`、`pg_database`、`pg_namespace`、`pg_class`、`has_*_privilege`で結果を記録する
7. テストDBを破棄する。既存DBは削除しない

テストSQL・操作ログにはパスワードを含めません。

テストDB・ロールの棚卸しは`docs/DB_TEST_ASSETS_AUDIT.md`と`scripts/yumeya-test-assets-audit.ps1`を使用します。監査は読み取り専用で、削除・`REASSIGN OWNED`・`DROP OWNED`は実行しません。

## 適用判断

## 2026-11-15 実測結果

対象は独立テストDB `yumeya_privtest_aa31def89392` です。`yumeya_portfolio`、既存の`yumeya_app`、Tomcat接続設定には適用していません。

| 検証 | 結果 |
|---|---|
| 所有権・権限移行 | PASS |
| SELECT | PASS |
| IDENTITY INSERT | PASS |
| 退室日＝次の入室日 | PASS |
| 重複予約拒否 | PASS（SQLSTATE `23P01`） |
| CANCELLED後の再予約 | PASS |
| ROLLBACK | PASS |
| CREATE / ALTER / DROP / TRUNCATE拒否 | PASS（SQLSTATE `42501`） |
| 直接`nextval()`拒否 | PASS（SQLSTATE `42501`） |
| sequence権限なしのIDENTITY INSERT | PASS |
| Java/JDBC `ReservationRepository` | PASS |

この結果により、アプリ実行ユーザーへidentity sequenceのUSAGE/SELECTを付与しなくても、現行Java実装の登録処理が成立することを独立DBで確認しました。

## 現DB適用準備（未実施）

### バックアップ

現在確認できる`yumeya-reservation-backups`はTomcat WAR・展開ディレクトリのバックアップであり、PostgreSQLの論理バックアップではありません。現DBへ適用する前に、管理者認証を端末入力して次を実施します。

```powershell
$backupDir = Join-Path $env:USERPROFILE 'Documents\secure-db-backups'
$backupFile = Join-Path $backupDir 'yumeya_portfolio_pre_privilege.dump'
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
pg_dump.exe -h 127.0.0.1 -p 5432 -U postgres -W -Fc -f $backupFile yumeya_portfolio
pg_restore.exe -l $backupFile
```

パスワードはコマンド、ファイル、Git、ログに保存しません。復元確認は別の検証DBへ行い、`yumeya_portfolio`へ直接復元しません。

### 適用順序

1. `yumeya_app`の所有者・ロール所属・権限を再取得
2. DBバックアップ取得と`pg_restore -l`確認
3. `yumeya_owner`作成（NOLOGIN、非SUPERUSER等）
4. `05_privilege_migration.sql`を対象DBへ適用
5. `05a_database_owner_migration.sql`を対象DB以外から適用
6. `yumeya_app`でDbCheck、SELECT、INSERT、取消、重複拒否を確認
7. Tomcatを再起動せず、既存接続が新接続時に動くことを確認

### ロールバック条件

- 権限不足によるDbCheck・登録・一覧・取消の失敗
- 所有者が想定外になった場合
- 既存の別用途ユーザーへ影響が出た場合
- バックアップの復元確認ができない場合

ロールバックは、監査で確認した元所有者を`06_privilege_rollback_template.sql`へ反映してから行います。自動実行はしません。

現時点の判定は、**独立DBの設計実証は完了、`yumeya_portfolio`への適用は未承認・未実施**です。
