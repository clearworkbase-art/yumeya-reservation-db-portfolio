# 画像利用権監査（2026-11-15）

## 結論

現リポジトリには画像の取得元URL、ライセンス記録、購入証明、撮影者・施設からの許諾記録がありません。したがって、公開用の画像としては権利確認済みと扱えません。画像は削除・上書きしていませんが、公開候補から一旦除外してください。

## 3分類

### 利用権の根拠が確認できた画像

**現在は該当なし。** `unsplash`を含むファイル名は手掛かりであって、取得元URLやライセンス記録そのものではありません。

### 出典・利用権が未確認の画像

Unsplash名を含む3ファイル、旅館・料理・背景・ロゴ・地図・SNSアイコンなど、Getty以外の全画像です。自作・購入済み・許諾済みである証拠を確認するまで公開候補から外します。

### 公開に使用すべきでない画像

`img/img/gettyimages-1153003908-2048x2048.jpg`はGetty Imagesを示す名称で、透かしが見える既知情報があります。正規ライセンスを確認できない限り、公開用ページに使用しません。

## 履歴に残る画像への対応

画像は初回Commitに含まれているため、今後のCommitから除外するだけではGit履歴から消えません。現段階では履歴を書き換えません。公開前には次のいずれかを、リポジトリ所有者の承認後に実施します。

1. **安全な推奨案:** 新しい公開用リポジトリを作り、権利確認済みのコード・資料・代替画像だけを初回Commitする。
2. **既存リポジトリを公開する案:** `git filter-repo`等で履歴から対象画像を除去し、全Commitの再書き換え、force push、共同利用者への影響確認を行う。
3. **非公開のまま提出する案:** リポジトリをPrivateに保ち、画像権利監査と除外計画を明記する。ただしPrivateでも権利確認は必要。

現時点の推奨は1です。既存リポジトリの履歴を書き換えず、公開用にクリーンな別リポジトリを構築します。

## 権利不明画像に依存しない代替デザイン案

- 写真を使わず、CSSの和紙風背景・罫線・単色面・客室コードの図形カードで構成する。
- ロゴは文字ベースの架空名称にし、アイコンは自作SVGまたはライセンス明記済みアイコンへ置換する。
- 地図は外部地図画像を使わず、所在地を架空のテキストと簡易図形で表現する。
- 写真が必要な場合は、権利証跡を保存できる素材だけを少数採用する。

## ファイル単位の確認結果

| ファイル群 | ローカルで確認できる根拠 | 判定 | 公開前の対応 |
|---|---|---|---|
| `img/img/gettyimages-1153003908-2048x2048.jpg` | Getty Imagesを示すファイル名。透かしが見えるという既知情報 | **高リスク** | 使用停止。正規ライセンス購入または権利確認済み素材へ差し替え |
| `img/img/daniel-58TJ5U21byY-unsplash.jpg` | Unsplash写真を示すファイル名のみ | 未確認 | 元のUnsplashページ、取得日、ライセンス、人物・施設・商標の確認を記録 |
| `img/img/masaaki-komori-qwPSnBvdhtI-unsplash.jpg` | Unsplash写真を示すファイル名のみ | 未確認 | 同上 |
| `img/img/samuel-berner-u8fS3_bSWdI-unsplash.jpg` | Unsplash写真を示すファイル名のみ | 未確認 | 同上 |
| `4317417_m.jpg`, `hotel0120150124133048.jpg`, `YAMA_*.jpg`, `R_*.jpg`, `T*.jpg`, `top*.jpg`, `Slide *.jpg`, `F*.jpg`, `spa*.jpg`, `meal_img.jpg` | 取得元・撮影者・許諾記録なし | **不明** | 原権利者またはライセンスを確認できるまで公開しない |
| `img/png/logo*.png`, `matsu.png`, `take.png`, `ume.png`, `icon_*.png`, `map.jpg`, `plan-*.png`, `bg*.jpg` | ロゴ・地図・装飾素材の出典記録なし | **不明** | 自作であること、または利用許諾を確認して記録 |

## 棚卸し対象ファイル（全件）

以下は今回の監査で存在を確認した画像ファイルです。個別のライセンス証拠がないため、Getty画像を除く全件も「権利確認待ち」としています。

```text
img/img/4317417_m.jpg
img/img/daniel-58TJ5U21byY-unsplash.jpg
img/img/F_beef.jpg
img/img/F_beef3.jpg
img/img/F_suki.jpg
img/img/F2.jpg
img/img/F3.jpg
img/img/FF.jpg
img/img/gettyimages-1153003908-2048x2048.jpg
img/img/hotel0120150124133048.jpg
img/img/masaaki-komori-qwPSnBvdhtI-unsplash.jpg
img/img/meal_img.jpg
img/img/R_m1.jpg
img/img/R_m2.jpg
img/img/R_m3.jpg
img/img/R_m4.jpg
img/img/R_m5.jpg
img/img/R_t1.jpg
img/img/R_t2.jpg
img/img/R_t3.jpg
img/img/R_t4.jpg
img/img/R_t6.jpg
img/img/R_u1.jpg
img/img/R_u2.jpg
img/img/R_u3.jpg
img/img/R_u4.jpg
img/img/Ru_6.jpg
img/img/samuel-berner-u8fS3_bSWdI-unsplash.jpg
img/img/Slide (1).jpg
img/img/Slide (19).jpg
img/img/Slide (2).jpg
img/img/Slide (3).jpg
img/img/Slide (4).jpg
img/img/Slide (5).jpg
img/img/Slide (6).jpg
img/img/Slide (7).jpg
img/img/Slide (8).jpg
img/img/Slide (9).jpg
img/img/spa_2.jpg
img/img/spa_title.jpg
img/img/T1.jpg
img/img/T2.jpg
img/img/T3.jpg
img/img/top (1).jpg
img/img/top (2).jpg
img/img/top (3).jpg
img/img/top (4).jpg
img/img/top (5).jpg
img/img/top (7).jpg
img/img/top4.jpg
img/img/YAMA_DSC0045.jpg
img/img/YAMA_DSC9933.jpg
img/png/bg.jpg
img/png/bg2.jpg
img/png/bg3.jpg
img/png/icon_fb.png
img/png/icon_insta.png
img/png/icon_tw.png
img/png/logo.yoko.png
img/png/logo.yoko2.png
img/png/logo.yoko2white.png
img/png/logo.yoko3.png
img/png/m-main (2).jpg
img/png/map.jpg
img/png/matsu.png
img/png/paper1.jpg
img/png/plan-1.png
img/png/plan-2.png
img/png/plan-3.png
img/png/take.png
img/png/top_m.jpg
img/png/top_m2.jpg
img/png/top_m3.jpg
img/png/top_white.png
img/png/top_white6.png
img/png/top.png
img/png/ume.png
```

## 判断基準

ファイル名に `unsplash` とあるだけでは、当該ファイルがUnsplashから取得されたことや、人物・施設・商標に関する追加権利が解決済みであることを証明できません。Gettyの透かしが残る画像は、少なくとも公開候補に含めないでください。

Unsplashの公式ライセンスは一般に商用利用を許可していますが、人物・施設・商標などの別の権利まで一律に保証するものではありません。実際に使用する画像ごとに元ページと利用条件を保存し、必要なら撮影者・施設の許諾を確認してください。

## 公開前チェックリスト

- [ ] Getty透かし画像を公開候補から外した
- [ ] 使用画像ごとに元URL、取得日、ライセンスを記録した
- [ ] 人物・施設・商標の追加権利を確認した
- [ ] 自作ロゴ・地図・図形は制作主体を記録した
- [ ] READMEと公開サイトに、未確認画像が残っていないことを確認した
