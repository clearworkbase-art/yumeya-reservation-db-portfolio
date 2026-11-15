# GitHub提出準備

## Commit候補

- `apps/yumeya-reservation/src/main/java/` のv2 Java実装
- `apps/yumeya-reservation/src/test/` のJUnit
- `apps/yumeya-reservation/db/` のスキーマ・検証SQL・権限移行SQL
- `apps/yumeya-reservation/docs/` のDB設計、最小権限、テスト、監査資料
- `apps/yumeya-reservation/README.md`
- `scripts/` のローカル検証・配備スクリプト
- `.editorconfig`

## Commitから除外

- `target/`、WAR、ログ、ローカル設定、パスワード
- `h -u origin main`
- 権利確認前のGetty画像・出典不明画像
- Tomcat配備バックアップ
- DBダンプや個人環境固有の認証情報

## 公開前の重要事項

画像は初回履歴に含まれているため、今後のCommitから除外するだけでは履歴から消えません。現リポジトリをPublic化する前に、権利確認済み素材だけで新規公開リポジトリを構築する案を第一候補とします。履歴書き換えは承認なしに実行しません。

最小権限化は独立テストDBで実測済みですが、`yumeya_portfolio`には未適用です。READMEやPRでは「テストDBで検証済み」「実DB未適用」と明記します。

## 推奨Commitメッセージ

```text
feat: add PostgreSQL reservation demo with least-privilege design
```

## PR案

- Push先: `feature/yumeya-db-v2`
- ベース: `main`
- 内容: PostgreSQL制約、JDBC CRUD、予約重複防止、取消履歴、独立DBでの最小権限実証
- 注意: 公開前に画像権利確認とCommit対象の最終選別が必要
