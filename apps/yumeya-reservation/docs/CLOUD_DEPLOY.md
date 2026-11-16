# 夢屋予約デモ：無料クラウド公開の準備

既存の旅館サイト（Netlify）は変更せず、**Java予約フォームだけ**をRenderに、DBをNeonに配置する構成です。

公開するのは架空予約の入力・確認・登録のみ。管理画面 `/admin/*` は `YUMEYA_PUBLIC_DEMO=true` のとき外部アクセス不可（404）。ローカルでは従来のアクセス制限を維持します。

## 全体構成

1. 既存の旅館サイト `https://creative-wisp-6affe7.netlify.app/` を維持
2. 別URL `https://（Renderのドメイン）/reservation` を予約画面として開く
3. Neon PostgreSQL（専用のテストDBと最小権限ユーザー）に架空予約を保存
4. デプロイ・DB接続・重複予約拒否を確認してから、Netlify側の「オンライン予約」リンクを差し替え

## Neon側

- Neon Freeで新しい専用プロジェクト／DBを作成する（既存DBは触らない）。
- 接続先で `db/01_schema.sql` をスキーマ所有者として**一度だけ**実行する。`rooms` 3件と `reservations` テーブルが作成される。
- Neonコンソールで別途 `yumeya_demo_app` のようなアプリ用LOGINロールを作成し、管理者として `db/05_neon_app_permissions.sql` を実行する。
- アプリ用ロールでSELECTとINSERTが可能で、CREATEやDROPが不可であることを実測する。`btree_gist` 拡張が利用できるかも確認する。
- 接続文字列は `jdbc:postgresql://HOST/DB?sslmode=verify-full` の形式をRender環境変数に登録し、`YUMEYA_DB_USER`、`YUMEYA_DB_PASSWORD` と分けて管理する。秘密情報をGitに入れない。

## Render側

- GitHubの `clearworkbase-art/yumeya-reservation-db-portfolio` にこの追加ファイルを反映後、Renderにサインインする。
- New → Blueprint → リポジトリ選択でルートの `render.yaml` を使用。**Free** のWebサービスのみを作成する。有料プランやRender Postgresを新規作成しない。
- DB接続情報3項目（`YUMEYA_JDBC_URL`, `YUMEYA_DB_USER`, `YUMEYA_DB_PASSWORD`）をRenderの秘密環境変数として登録。`YUMEYA_PUBLIC_DEMO=true` は構成に含む。
- DockerコンテナがTomcat9を起動し、RenderのPORTにHTTP接続する。HTTPSはRenderが終端する。
- `/health` が `app ready` を返すことを確認してから、`/reservation` の予約登録を試す。

## 公開前のチェック

- ダミーの客室・日付・人数のみを使用し、氏名や連絡先を収集しない
- 予約保存／完了画面のID表示が実際のDBに登録されていることを確認
- 同室・同日程の2件目が拒否されることを確認
- `/admin/reservations` が必ず404になることを確認
- サーバーの環境変数がGitHub、スクリーンショット、ログに含まれていないことを確認
- **画像権利が未確認の元サイト画像を、新しいコードやクラウド用パッケージに複製しない**
- ランニングコスト、利用上限とサービスの停止動作を確認

## 注意

この構成は趣味・面接用のデモです。認証・監視・WAF・接続プール・大規模な濫用防止は実装されていません。公開書き込みはデモ用の簡易上限（1アプリプロセス当たり30回/時）に抑えますが、再起動で消える制限であり、強固な不正利用対策ではありません。本番の予約サイトとしては使わないでください。

Render無料サービスは無アクセス15分で休止し、再アクセス時の起動待ちが生じます。Neon無料DBも無アクセス時は休止します。料金・無料枠は適用時に管理画面で再確認してください。
