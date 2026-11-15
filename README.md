# Career Portfolio v2｜夢屋旅館予約システム

DBエンジニア採用向けの提出用コピーです。Git履歴、`.git`、ビルド成果物、DBダンプ、バックアップ、権利未確認画像は含めていません。

## 内容

- Java 17 / Maven / Servlet/JSP / PostgreSQL / JDBC
- PK・FK・CHECK制約
- PostgreSQL `EXCLUDE USING gist`による予約期間重複防止
- 取消履歴を保持する状態遷移
- DDL所有者とアプリ実行ユーザーの分離設計
- 独立テストDBでの最小権限・CRUD・Java/JDBC実証記録

最小権限化の実証は独立テストDBで実施済みです。開発用DB `yumeya_portfolio` には所有権・権限変更を適用していません。

## 技術資料

- [DB設計](apps/yumeya-reservation/docs/DB_DESIGN.md)
- [最小権限化](apps/yumeya-reservation/docs/DB_LEAST_PRIVILEGE.md)
- [テスト計画・結果](apps/yumeya-reservation/docs/TEST_PLAN_V2.md)
- [実装概要](apps/yumeya-reservation/docs/IMPLEMENTATION.md)
- [画像権利監査](apps/yumeya-reservation/docs/IMAGE_RIGHTS_AUDIT.md)
- [提出方針](apps/yumeya-reservation/docs/GITHUB_SUBMISSION_PLAN.md)

## ローカル確認

```powershell
mvn -f .\apps\yumeya-reservation\pom.xml clean package
```

DBパスワードはソースコードや資料へ記載しません。アプリは環境変数から接続情報を取得します。

## 画像について

提出用コピーでは、Getty Imagesおよび出典・利用権未確認の画像をすべて除外しました。静的ページはCSSプレースホルダーで表示し、権利確認後に差し替え可能な構成です。

## 制約

管理画面はlocalhost制限のみで、本番認証・本番認可ではありません。外部公開用サービスではなく、DB設計とJava/JDBC連携を説明するローカルデモです。

AIによる実装補助を一部利用しています。実装内容と検証結果は、同梱資料とソースに基づいて確認できるようにしています。
