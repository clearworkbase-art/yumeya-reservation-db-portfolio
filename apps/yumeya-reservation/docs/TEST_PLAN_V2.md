# v2 テスト記録（2026-11-15、Windows 11ローカル環境）

実行済みと未実行を分けて記載します。過去の実行結果を今回の監査結果として水増ししていません。

## Java自動テスト

- [x] `mvn -f ./apps/yumeya-reservation/pom.xml clean package` が `BUILD SUCCESS`
- [x] JUnit 7件成功（`ReservationRulesJUnitTest` 5件、`LocalAdminAccessTest` 2件）

## PostgreSQL検証

- [x] DbCheckでPostgreSQL接続成功、`rooms=3`、予約件数を確認
- [x] HTTP Smokeで正常な予約登録と一覧取得を確認
- [x] HTTP Smokeで同室・重複日程を拒否することを確認（アプリ経由）
- [ ] 退室日＝別予約の入室日は許可する
- [x] HTTP Smokeで取消後の状態が `CANCELLED` になることを確認
- [ ] キャンセル後に重複日程の新規予約ができることを単独確認
- [ ] `db/02_demo_queries.sql` が動き、JOIN・EXPLAIN結果を説明できる

## 画面確認

- [ ] トップページのヘッダー高さがPCで過大にならないことを目視確認
- [x] HTTP Smokeで予約登録 → 一覧 → 重複拒否 → 取消を確認
- [ ] スマホ幅でメニュー・予約画面が崩れない
- [ ] 不正な日付入力でエラーが出る
- [ ] DB停止時に例外や個人情報を表示せず503が返る
- [x] `127.0.0.1` 前提のローカル管理画面がHTTP 200で表示されることを確認

## 実行環境と補足

- Java 17、Maven 3.10、Tomcat 9.0.124、PostgreSQL 17、JDBC 42.7.14
- Smokeで作成したテスト予約は削除せず、`CANCELLED` の履歴として保持（予約ID 1）
- DBパスワードは表示・保存・記録していない
- 追加の実DB更新を伴う検証は、今回の監査では安全のため実施していない

## 追加検証計画（専用一時DBのみ）

実DB `yumeya_portfolio` には実行しません。専用の一時DBを用意し、`01_schema.sql`を実行した後に`04_tempdb_validation.sql`を実行します。検証SQLの最後は`ROLLBACK`です。

| ケース | 期待結果 | 判定 |
|---|---|---|
| `check_in < check_out` | 登録成功 | 未実行 |
| 退室日＝次予約の入室日 | `[)` により登録成功 | 未実行 |
| 完全重複・部分重複 | `23P01`で拒否 | アプリSmokeで重複拒否のみ確認。SQL単体は未実行 |
| CANCELLED予約と同期間 | 取消行を残したまま再登録成功 | 未実行 |
| 二重送信 | PRGで通常再読込を防止。ただし同時POSTの一意性保証は未実装のため、別セッションで確認 | 未実行 |
| 同時予約 | 2セッションから同じ部屋・期間を登録し、一方だけ成功、他方が`23P01` | 未実行 |
| ロールバック | 失敗した一連のテストデータが残らない | 未実行 |
| SELECTのEXPLAIN | 更新なしで計画を取得し、条件・並び順のインデックス利用を説明 | 未実行 |

### 二重送信と同時予約の注意

`CompleteServlet.java:31-36`は成功後にセッションの保留予約を削除し、PRGへ遷移します。通常の再読込対策にはなりますが、同じPOSTが並列に到着する場合の冪等性キーはありません。採用資料では「通常の再送防止は実装済み、並列二重送信の完全な冪等性は改善課題」と説明します。

同時予約の整合性は、Java側の事前SELECTではなく、`db/01_schema.sql:25-28`の排他制約で確認します。`EXPLAIN ANALYZE`は更新文に付けず、読み取り専用SELECTだけに使用します。

## 最小権限化の実証テスト

既存の`yumeya_portfolio`には接続せず、次のスクリプトが作成する一意なテストDB・テストロールだけを使用します。

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\yumeya-privilege-isolated-test.ps1
```

スクリプトは管理者パスワードを端末入力し、GUID由来の一意な`yumeya_owner_test_...`（NOLOGIN）と`yumeya_app_test_...`（LOGIN）、テストDBを作成します。既存名を再利用・上書きせず、テスト資産は自動削除しません。結果確認と承認後に別途削除します。

DB・ロール作成前に、管理者接続、psql終了コード、標準出力、標準エラー、`client_encoding=UTF8`を事前確認します。ここで失敗した場合はCREATE処理へ進みません。

SQLはWindows PowerShell 5.1の文字コード変換を避けるため、一時ファイルを作らずUTF-8標準入力で`psql -f -`へ渡します。子プロセスの`PGCLIENTENCODING=UTF8`も確認します。

途中停止した場合の残存確認は、`yumeya-db-permissions-audit.ps1`の末尾にあるテストDB・テストロール一覧で読み取り専用に行います。削除や再利用はしません。

### 最新試行の記録

対象DB: `yumeya_privtest_22530986dbf5`

- 事前接続・`client_encoding=UTF8`: 成功
- テストDB/ロール作成: 成功
- 所有権・権限移行: 成功
- `rooms` SELECT: 成功
- IDENTITY INSERT: 成功
- 退室日＝次の入室日: 成功
- 重複予約拒否: 成功
- CANCELLED後の再予約: 成功
- トランザクションROLLBACK: 成功
- CREATE/ALTER/DROP/TRUNCATE拒否: 成功
- 停止箇所: direct `nextval()`拒否の日本語エラー判定
- 修正方針: `42501`と非0終了コードを使い、エラー文言に依存しない判定へ変更
- 既存テストDB/ロール: 削除・初期化しない。次回は新しいGUID名で再実行する

実証項目は、SELECT、identity INSERT、取消UPDATE、重複期間の`23P01`、退室日＝次の入室日、CANCELLED後の再予約、ROLLBACK、CREATE/ALTER/DROP/TRUNCATE拒否、Java `ReservationRepository`のJDBC処理です。

identity sequenceは、テスト用アプリロールにUSAGE/SELECTを付与しない状態で通常のIDENTITY INSERTが成功することを確認します。その後、直接`nextval()`を呼ぶSQLは権限不足で拒否されることを確認します。Java `ReservationRepository`はsequence関数を直接呼ばず、IDENTITY列を省略したINSERTと`RETURNING reservation_id`だけを使うため、個別sequence権限を要求しない構成です。

### 完了記録

成功したテストDB: `yumeya_privtest_aa31def89392`

- [x] 所有権・権限移行
- [x] SELECT、IDENTITY INSERT
- [x] checkout/checkin境界
- [x] 重複予約拒否（`23P01`）
- [x] CANCELLED後の再予約
- [x] ROLLBACK
- [x] CREATE / ALTER / DROP / TRUNCATE拒否（`42501`）
- [x] 直接`nextval()`拒否（`42501`）
- [x] sequence権限なしのIDENTITY INSERT
- [x] Java/JDBC `ReservationRepository`

この実績は独立テストDBだけの結果です。既存の`yumeya_portfolio`には権限変更を適用していません。
