# GitHubで原本を守りながら進める手順

1. GitHubで **Private** リポジトリ `portfolio-java-demos` を新規作成する。作成画面ではREADME等の自動生成をオフにする。
2. PCにGitを入れ、VS Codeの「フォルダーを開く」でこのプロジェクトを開く。
3. VS Codeの「ターミナル」を開く。ユーザー名、メールアドレスを設定していなければ `git config --global user.name "(GitHubで使う表示名)"`、`git config --global user.email "(コミット用メール)"` を設定。
4. `git init -b main` → `git add .` → `git status` で機密ファイルが入っていないか確認 → `git commit -m "Initial safe import"`。
5. GitHubが示す自分のURL（例: `https://github.com/<username>/portfolio-java-demos.git`）を確認し、`git remote add origin <URL>` → `git push -u origin main`。認証が求められたらGit Credential Managerなど画面の指示を確認し、認証情報はチャットに貼らない。
6. 機能追加前に `git switch -c feature/nursery-visit` でブランチ作成。`git add .` → `git commit -m "Add nursery visit demo"` → `git push -u origin feature/nursery-visit`。
7. GitHub上でPull Requestを作り、変更内容と機密ファイルをレビューしてからマージする。

**注意:** このZIPには `.git/` は含まれず、GitHubへのアップロードやコミットも行われていません。`main`への直接pushは最初の安全な取り込み以外では避け、機能開発はブランチで進めてください。

GitHub上に公開する前に、画像の権利、架空施設の表記、リンク先を確認してください。旧ポートフォリオ全体にある顧客可視化PDFなどの実務情報はこのプロジェクトに含めていません。
