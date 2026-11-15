<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html><html lang="ja"><head>
<meta name="robots" content="noindex, nofollow">
<meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>内容確認｜夢屋旅館</title>
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/common/reset.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/common/common.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/page/reservation.css">
</head><body>
<div class="portfolio-demo-banner" role="note"><strong>架空の旅館・ポートフォリオ作品</strong> ｜ 実際の宿泊予約は受け付けていません。</div>
<header class="reservation-header"><a href="${pageContext.request.contextPath}/index.html">銀山温泉 夢屋旅館</a><span>宿泊予約DBデモ</span></header>
<main class="reservation-container"><p class="eyebrow">RESERVATION SYSTEM · PostgreSQL</p><h1>入力内容の確認</h1>
<p class="demo-notice">「デモ予約をDBに保存」を押すと、ローカルPostgreSQLに架空の予約レコードが保存されます。実際の宿泊予約・決済・メール送信は行われません。</p>
<p class="error" role="alert" ${empty errorMessage ? 'hidden' : ''}>${errorMessage}</p>
<ol class="steps"><li>1. 条件入力</li><li class="current">2. 内容確認</li><li>3. DB登録完了</li></ol>
<dl class="review-list"><div><dt>客室</dt><dd>${reservation.roomLabel}</dd></div>
<div><dt>チェックイン</dt><dd>${reservation.checkIn}</dd></div>
<div><dt>チェックアウト</dt><dd>${reservation.checkOut}</dd></div>
<div><dt>泊数</dt><dd>${reservation.nights}泊</dd></div><div><dt>人数</dt><dd>${reservation.guests}名</dd></div></dl>
<div class="actions"><a class="text-link" href="${pageContext.request.contextPath}/reservation">入力し直す</a>
<form method="post" action="${pageContext.request.contextPath}/reservation/complete">
<input type="hidden" name="csrfToken" value="${csrfToken}"><button type="submit">デモ予約をDBに保存</button></form></div>
</main><footer class="reservation-footer">&copy; 夢屋旅館 学習用デモ</footer></body></html>
