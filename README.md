# 夢屋旅館｜宿泊予約システム

架空の旅館を題材にした、Java Servlet/JSPとPostgreSQLの学習用アプリです。客室と宿泊日を選んで予約し、登録内容の確認や取消まで行えるようにしています。

画面を作るだけでなく、予約データをデータベースに保存し、同じ客室を同じ期間に二重予約できないようにするところまで取り組みました。

## できること

- 宿泊日・客室・人数を入力して予約する
- 入力内容を確認し、PostgreSQLへ保存する
- ローカルの管理画面で予約を検索し、取り消す
- 取り消した予約も履歴として残す

## DBで工夫したところ

**予約の重複はJava側の確認だけに頼らず、DB側でも防いでいます。**

空室を確認した直後に別の予約が入ることもあるため、PostgreSQLの排他制約（`EXCLUDE USING gist`）を使いました。宿泊期間は `[)`（チェックイン日を含み、チェックアウト日を含まない）として扱い、同じ日のチェックアウトと次のチェックインは両立できるようにしています。

予約の取消は行を削除するのではなく、`CANCELLED` への更新で管理しています。JavaからのSQL実行にはJDBCの `PreparedStatement` を使っています。

## 確認したこと

- Mavenビルド成功、JUnit **7件成功**
- ローカル環境で予約登録・一覧表示・重複拒否・取消を確認
- 別のテスト用DBで、予約の境界日付、重複拒否、ROLLBACK、DB権限の制限、Java/JDBCからの操作を確認

DBの管理権限とアプリ実行権限を分ける構成は、**独立したテスト用DBで検証済み**です。普段使っている開発用DBには、まだその権限変更を適用していません。

詳しい条件と未検証項目は[テスト記録](apps/yumeya-reservation/docs/TEST_PLAN_V2.md)にまとめています。

## ソースコードと資料

- [Java・JSP・SQLの実装](apps/yumeya-reservation/)
- [DB設計とER図](apps/yumeya-reservation/docs/DB_DESIGN.md)
- [予約処理の流れ](apps/yumeya-reservation/docs/IMPLEMENTATION.md)
- [DB権限の設計と検証](apps/yumeya-reservation/docs/DB_LEAST_PRIVILEGE.md)
- [ローカルでの起動手順](apps/yumeya-reservation/docs/WINDOWS_SETUP.md)

**使用技術:** Java 17、Servlet/JSP、JDBC、PostgreSQL 17、Maven、Tomcat 9、HTML/CSS/JavaScript

## 公開範囲と今後の課題

現時点で公開しているのはコードと資料です。Web上の予約デモは別途準備中で、動作確認が完了してからリンクを追加します。ローカルではTomcatとPostgreSQLを使って動作させています。

管理画面はローカル利用に限定しており、クラウドのデモモードでは無効化する構成を準備しています。本番向けのログイン認証は未実装です。DB接続プールや並列POSTの完全な二重送信対策なども今後の課題です。画像は利用権を確認できていないため、公開版から除外しています。

制作では、コードの作成・修正や問題の調査にAIの支援を利用しました。実際に確認できた動作と、まだ試していないことを分けて記載しています。
