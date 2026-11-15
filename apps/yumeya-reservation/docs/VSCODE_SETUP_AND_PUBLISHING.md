# VS Codeで夢屋旅館のServlet/JSP予約デモを動かす手順（2026-11-14）

## 現時点での確認結果
- このプロジェクトはMaven WAR形式、Java 11ターゲット、`javax.servlet-api:4.0.1`（Tomcat 9対応）です。
- `src/main/webapp/index.html` はHTMLのトップページ、`WEB-INF/views/*.jsp` は予約フローの画面です。
- `.html` をVS CodeやLive Serverで直接開くと静的部分は見られますが、`/reservation` を動かすにはTomcatが必要です。
- v1.1は全HTML/JSPに`noindex, nofollow`を設定し、架空施設のデモと表示し、電話・地図の外部リンクを無効化した安全対策版です。ブラウザ実機での動作は未検証です。

## 1. PCに準備するもの
1. Visual Studio Code（導入済み）
2. VS Code拡張：`Extension Pack for Java`（Microsoft）
3. JDK 17（インストール後、PowerShellで `java -version`、`javac -version`）
4. Apache Maven 3.8+（`mvn -version`）
5. Apache Tomcat **9**（https://tomcat.apache.org/download-90.html からCore zipを解凍）
6. Git（`git --version`、後でGitHubへ登録するとき）

Eclipseは不要です。メイン/サブPCに同じプロジェクトをGitHub経由で同期できますが、JDK、Maven、Tomcatは各PCに個別に必要です。

## 2. プロジェクトを開いてビルド
1. ZIPを任意の作業フォルダへ展開（機密情報のない場所）。
2. VS Code → ファイル → フォルダーを開く → `pom.xml` がある `yumeya_reservation_v1_1_demo_safety_20261114` を選ぶ。
3. `ターミナル` → `新しいターミナル` → コマンド：

```powershell
java -version
javac -version
mvn -version
mvn clean package
```

`target/yumeya-reservation.war` が作成されます。Mavenの初回実行にはネット接続が必要です。

## 3. Tomcat 9で起動
1. `target/yumeya-reservation.war` をTomcat 9の `webapps` フォルダにコピー。
2. Tomcatの `bin/startup.bat` を起動。
3. `http://localhost:8080/yumeya-reservation/` をブラウザで開く。
4. トップページの「オンライン予約」を押してフォーム入力→確認→デモ完了を確認。
5. 終了時は `bin/shutdown.bat` を実行。

8080番ポートが使われている場合、Tomcatの `conf/server.xml` 側のポート設定確認が必要です。`JAVA_HOME`の設定が必要なPCもあります。

## 4. 本番公開は別判断
- 現行サーバーが静的WebホスティングやPHPのみの場合、WARファイルはアップロードするだけでは動きません。
- 既存ホスティングにTomcat機能がない場合、**ポートフォリオ本体は現行サーバー**、**Java予約デモは別のTomcat対応環境**にする選択があります。
- 設計説明、GitHub（権限確認済みのコード）、画面録画だけを既存サイトで公開する方法もあります。
- サーバーが何か不明な場合、ホスティング会社とプラン名または公開URLを確認してからデプロイ先を決めます。

## 5. Google検索・誤認・プライバシー対策
- このv1.1はHTML/JSPに `<meta name="robots" content="noindex, nofollow">` を指定しています。Googleなど対応する検索エンジンに検索掲載を避けるよう指示しますが、**URLを知る人のアクセスは防止しません**。
- `robots.txt`でクロールを禁止すると、検索エンジンが`noindex`を確認できなくなる場合があります。
- 非公開にしたい場合はパスワード保護したサーバーで運用してください。
- 公開するなら架空施設・技術デモ・実際の予約不可を全ページに表示し、電話・地図・問い合わせ先など本物と誤認される要素を削除します。
- 画像・ロゴなど第三者の権利関係を確認してから公開してください。
- 利用者の氏名・電話・メール、決済情報を本デモで収集しないでください。
- 本番公開前にTLS（HTTPS）、サーバー管理、アクセス制限、ログ、更新体制、セキュリティの確認が必要です。

## 6. GitHubでのバージョン管理
- 初回は**Private**リポジトリを推奨。ソース内に個人情報、顧客情報、利用許諾のない素材、APIキーがないか確認してください。
- `main` は安定版、改修は `feature/...` ブランチで実施し、Pull Requestで差分を確認して統合します。
- GitHubに保存しただけでは実際のTomcatサーバーへのデプロイは行われません。
