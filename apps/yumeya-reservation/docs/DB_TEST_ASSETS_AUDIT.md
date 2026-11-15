# 独立DB・テストロール棚卸し

## 調査方法

削除を行わず、次の読み取り専用スクリプトでクラスタ内のテスト資産を確認します。

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\yumeya-test-assets-audit.ps1
```

確認対象は次のパターンです。

- `yumeya_privtest_*`
- `yumeya_owner_test_*`
- `yumeya_app_test_*`

DBごとにDB所有者、接続可否、テーブル・sequence所有者、共有依存数を確認し、ロールごとにLOGIN/SUPERUSER/CREATEDB/CREATEROLE/BYPASSRLSとロール所属を確認します。

## 最新の成功資産

| 種別 | 名前 | 状態 |
|---|---|---|
| テストDB | `yumeya_privtest_aa31def89392` | 検証証跡として保持。削除していない |
| テスト所有者ロール | 実行ログに表示された`yumeya_owner_test_*` | 削除していない。実際の所有者・依存関係は監査コマンドで確認 |
| テストアプリロール | 実行ログに表示された`yumeya_app_test_*` | 削除していない。実際の属性・所属は監査コマンドで確認 |

過去の失敗試行を含む全資産は、管理者パスワードを端末入力した読み取り専用監査の出力で確定します。現時点で削除可否を推測して削除することはありません。

## 削除可否の判断基準

- テストDB:接続中セッションがなく、検証証跡の保管期間を終え、ユーザーが削除を承認した場合のみ削除候補
- テストロール:所有DB・所有オブジェクト・ロール所属・共有依存がないことを確認した場合のみ削除候補
- `DROP OWNED`、`REASSIGN OWNED`、`DROP ROLE`は自動実行しない

成功した`yumeya_privtest_aa31def89392`は、採用資料の検証証跡として一時保持します。
