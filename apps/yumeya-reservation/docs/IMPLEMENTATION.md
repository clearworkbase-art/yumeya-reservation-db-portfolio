# 予約処理の流れ

画面から入力された予約が、どのようにデータベースへ保存されるかを整理しました。

1. `ReservationServlet` が入力画面 `reservation.jsp` を表示し、セッションとCSRFトークンを用意します。
2. `ConfirmServlet` が入力値を受け取り、`ReservationRules` で日付・人数などを検証します。問題がなければ、確認待ちの内容をセッションに保存して `confirm.jsp` を表示します。
3. `CompleteServlet` が確認待ちの予約を `ReservationRepository.insert()` に渡します。
4. `ReservationRepository` はJDBCと `PreparedStatement` を使って `reservations` テーブルに登録し、`RETURNING reservation_id` から予約IDを受け取ります。
5. 登録できた場合は、確認待ちのデータをセッションから外してリダイレクトします。完了画面へのGETでは登録済み予約をDBから取得して表示します。

## 重複予約への対応

同じ客室・重複する宿泊期間はPostgreSQLの排他制約で拒否します。`ReservationRepository` はSQLSTATE `23P01` を受け取ると、重複予約として扱います。Javaの入力検証だけでDB上の重複を防いでいるわけではありません。

## 予約一覧と取消

ローカル用管理画面の `AdminReservationServlet` は `ReservationRepository.search()` で予約を検索します。取消操作は `CancelReservationServlet` から `ReservationRepository.cancel()` を呼び出し、データを削除せず `CANCELLED` に更新します。

## 実装の範囲と制約

- 入力規則は `ReservationRules` に分け、JUnitで確認できるようにしています。
- 予約登録・取消はそれぞれ1つのSQL文で行っています。複数SQLをまとめる明示的なトランザクション処理は未実装です。
- 成功後のリダイレクトは通常のページ再読込による再送を防ぐためのものです。並列POSTの完全な冪等性は保証していません。
- 管理画面にはlocalhost向けの制限がありますが、本番用の認証・認可はありません。
- 実装にはAIの支援も利用しています。面接では、確認したコードやテスト結果と、自分で説明できる範囲を区別します。
