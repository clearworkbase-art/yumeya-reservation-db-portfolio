# 夢屋旅館｜宿泊予約システム

架空の旅館を題材にした、**Java Servlet/JSPとPostgreSQLの学習用Webアプリ**です。客室・宿泊日・人数を入力し、確認画面からデモ用データベースに予約を登録できます。

## アプリを試す

- [旅館Webサイト](https://creative-wisp-6affe7.netlify.app/)
- [宿泊予約デモ](https://yumeya-reservation-demo.onrender.com/reservation)

> **初回表示について：** 予約デモはRenderの無料サーバーで公開しています。アクセスがないと休止するため、初回表示に30〜60秒程度かかる場合があります。実際の宿泊予約や決済は行われません。氏名・連絡先の入力も不要です。

## 主な機能

- 客室・チェックイン日・チェックアウト日・人数の入力と確認
- 予約データのPostgreSQLへの保存
- 同じ客室・重複する日程の予約を防止
- ローカル環境での予約検索・取消（公開デモでは管理画面を無効化）

## データベースで工夫したこと

**二重予約をJava側の入力チェックだけでなく、データベース側の制約でも防止しています。**

同じ客室の宿泊期間が重なる予約は登録できません。一方、ある予約のチェックアウト当日を、別の予約のチェックイン日にすることはできます。また、取消した予約は削除せず、状態を変更して履歴を残します。

[DB設計（ER図・テーブル構成）](apps/yumeya-reservation/docs/DB_DESIGN.md)

## 使用技術

- **サーバー側：** Java 17、Servlet/JSP、JDBC、Tomcat 9
- **データベース：** PostgreSQL、SQL（クラウドはNeonを使用）
- **画面：** HTML、CSS、JavaScript
- **開発・公開：** Maven、GitHub、Docker、Render、Netlify

## 確認したこと

- Mavenビルド成功、JUnitテスト7件成功
- ローカル環境で予約登録・一覧取得・重複登録の拒否・取消を確認
- 独立したテスト用DBで、日付境界・取消後の再予約・ロールバック・DB権限制限・Java/JDBC連携を確認
- 公開デモからクラウドのPostgreSQLへ予約データを保存できることを確認

テスト環境ごとの詳細や未確認項目は[テスト記録](apps/yumeya-reservation/docs/TEST_PLAN_V2.md)に残しています。

## ソースコード・技術資料

- [Java・JSP・SQLの実装](apps/yumeya-reservation/)
- [DB設計（ER図付き）](apps/yumeya-reservation/docs/DB_DESIGN.md)
- [予約処理の流れ](apps/yumeya-reservation/docs/IMPLEMENTATION.md)
- [ローカルでの起動方法](apps/yumeya-reservation/docs/WINDOWS_SETUP.md)

## 制作について

職業訓練で学んでいるJava・SQLを活用し、**Javaの実装やデータベース接続などにAIの開発補助を利用して制作**しました。動作確認できた内容と、まだ実施していない検証を区別して記載しています。

本作品は学習・ポートフォリオ用のデモです。本番用の認証・決済機能はありません。管理画面はローカル利用に限定しています。元の旅館Webサイトにある画像は、公開・応募利用に先立ち権利の確認が必要です。
