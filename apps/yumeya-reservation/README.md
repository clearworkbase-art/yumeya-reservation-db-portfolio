# 夢屋旅館 v2：PostgreSQL/JDBCによる宿泊予約DBデモ

既存のWebサイトとServlet/JSPの入力画面を活用した、**ローカル専用・架空データ専用**の個人制作・学習作品です。実在する旅館の予約は受け付けません。採用担当者に、DB設計・制約・JDBC連携・整合性制御を説明できることを目的にしています。

## プロジェクト概要

- 予約入力から確認、PostgreSQLへの保存、予約一覧、取消までをServlet/JSPで実装
- `rooms` と `reservations` を外部キーで関連付け、予約期間の重複をDB制約で防止
- DBパスワードはソースコードに置かず、Tomcatプロセスの環境変数から取得
- AIによる実装補助を一部利用。実装内容・検証結果はこのリポジトリのソースと資料に基づいて確認できるようにしています

## DB設計・実装上の工夫

- `PRIMARY KEY`、`FOREIGN KEY`、`NOT NULL`、`CHECK` で不正な状態をDB側でも拒否
- `EXCLUDE USING gist` と半開区間 `[)` の `daterange` で、同室の確定予約が同時実行でも重複しない設計
- 取消は削除せず `status = 'CANCELLED'` と `cancelled_at` を更新し、履歴を保持
- JDBCは `PreparedStatement` を使用し、SQLインジェクションを避ける
- 1文のINSERT/UPDATEはDBの原子性で完結。複数業務処理をまたぐトランザクション管理は今後の改善対象
- 独立テストDBで、アプリロールから不要なCREATE/ALTER/DROP/TRUNCATEと直接`nextval()`を拒否しつつ、sequence権限なしのIDENTITY INSERTが成功することを実測

詳細は [`docs/DB_DESIGN.md`](docs/DB_DESIGN.md) を参照してください。
最小権限化の移行設計・実測結果は [`docs/DB_LEAST_PRIVILEGE.md`](docs/DB_LEAST_PRIVILEGE.md)、テストDB資産の扱いは [`docs/DB_TEST_ASSETS_AUDIT.md`](docs/DB_TEST_ASSETS_AUDIT.md) を参照してください。

## 主な機能

- `DbConnection.java`: 環境変数からJDBC接続情報を取得し、PostgreSQLドライバーを明示初期化
- `ReservationRepository.java`: PreparedStatementでINSERT/SELECT/JOIN/UPDATE
- `CompleteServlet.java`: DB保存 → POST/Redirect/GET（保存失敗時503）
- 管理一覧 `/admin/reservations`: ローカル専用検索・架空予約キャンセル
- `db/01_schema.sql`: 初期スキーマ、客室3件の投入、制約・インデックス
- `db/04_tempdb_validation.sql`: 実DBを変更せずに境界条件・取消再予約・SELECT実行計画を検証する一時DB用SQL
- JUnit 5の入力・ローカルアクセスルールテスト

## 開発環境

Java 17、Maven 3.10、Tomcat 9、PostgreSQL 17、PostgreSQL JDBCドライバー 42.7.14。Javaコンパイラの `release` は11設定で、JDK17でビルドします。

初回導入と1コマンド操作は [`docs/WINDOWS_SETUP.md`](docs/WINDOWS_SETUP.md) を参照してください。

## 提出用コピーの画像方針

この提出用コピーでは、Getty Imagesおよび出典・利用権未確認の画像を含めていません。静的HTMLはCSSプレースホルダーで表示します。元リポジトリの画像ファイルは削除・上書きしていません。

## 2026-11-15時点の検証結果

- Maven `clean package`: 成功
- JUnit: 7件成功
- PostgreSQL接続確認: 成功（`rooms=3`、予約件数確認）
- HTTP Smoke: 登録・一覧・重複拒否・取消を成功
- テスト予約は削除せず、`CANCELLED` の履歴として保持
- 最小権限テストDB `yumeya_privtest_aa31def89392`: 所有権分離、CRUD、境界条件、`23P01`、`42501`、ROLLBACK、Java/JDBCを成功
- 上記最小権限化はテストDBのみで実施。既存の`yumeya_portfolio`には未適用

実行条件と未検証項目は [`docs/TEST_PLAN_V2.md`](docs/TEST_PLAN_V2.md) に記録しています。過去の実行結果と今回の監査結果を混同しないよう、日付を付けています。

## 制約・公開前の注意

- 認証、本番向け認可、DB接続プール、監視は未実装。**外部公開禁止**
- `LocalOnlyFilter` はローカルアクセス制限のデモであり、本番認証の代替ではない
- `noindex` は閲覧制限ではない
- 画像・ロゴ・写真の権利確認が完了するまで、公開候補から除外する
- 画像の棚卸しは [`docs/IMAGE_RIGHTS_AUDIT.md`](docs/IMAGE_RIGHTS_AUDIT.md) に記録しています

## 今後の改善計画

1. 実DBバックアップ・復元確認後、承認を得てDDL実行者とアプリ実行者を分離する
2. 接続プール、監査ログ、認証・認可を導入する
3. 境界日付・同時実行・DB障害・権限不足の自動テストを追加する
4. 出典と利用許諾を確認した画像だけで公開用画面を構成する
