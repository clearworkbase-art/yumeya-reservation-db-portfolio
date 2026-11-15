# 実装の説明（面接で説明できる範囲）

1. `index.html` / `u_room/index.html` の予約リンクから `ReservationServlet` へGET
2. `reservation.jsp` はクライアントの入力フォーム。csrfTokenとセッションを使用
3. POST `ConfirmServlet` でCSRF照合→`ReservationRules` で入力検証
4. 有効な場合だけ `ReservationDraft` をHTTPセッションへ保存し、確認画面JSPへforward
5. POST `CompleteServlet` でPendingデータを消費して完了ページへredirectし、GETで表示

`ReservationRules` をServletから分離したのは、入力規則を単体テストしやすくするため。予約可能かどうかをDBで判定する機能はありません。AIが作成した部分をそのまま「自分が手書きで実装した」と言わず、自分のレビュー・理解・テスト範囲を説明してください。
