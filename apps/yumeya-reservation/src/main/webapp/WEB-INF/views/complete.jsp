<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html><html lang="ja"><head>
<meta name="robots" content="noindex, nofollow">
<meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>DB登録完了｜夢屋旅館</title>
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/common/reset.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/common/common.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/page/reservation.css">
</head><body>
<div class="portfolio-demo-banner" role="note"><strong>架空の旅館・ポートフォリオ作品</strong> ｜ 実際の宿泊予約は受け付けていません。</div>
<header class="reservation-header"><a href="${pageContext.request.contextPath}/index.html">銀山温泉 夢屋旅館</a><span>宿泊予約DBデモ</span></header>
<main class="reservation-container"><p class="eyebrow">RESERVATION SYSTEM · JDBC</p><h1>架空データを保存しました</h1>
<ol class="steps"><li>1. 条件入力</li><li>2. 内容確認</li><li class="current">3. DB登録完了</li></ol>
<p class="demo-notice"><strong>学習用PostgreSQLに保存しただけです。</strong> 実際の予約、施設への通知、決済・メール送信は一切行われません。</p>
<dl class="review-list"><div><dt>デモ登録ID</dt><dd>${saved.id}</dd></div>
<div><dt>客室</dt><dd>${saved.roomLabel}</dd></div>
<div><dt>チェックイン</dt><dd>${saved.checkIn}</dd></div>
<div><dt>チェックアウト</dt><dd>${saved.checkOut}</dd></div>
<div><dt>人数</dt><dd>${saved.guests}名</dd></div><div><dt>状態</dt><dd>${saved.statusLabel}</dd></div></dl>
<div class="actions"><a class="text-link" href="${pageContext.request.contextPath}/index.html">旅館サイトに戻る</a>
<a class="secondary-button" href="${pageContext.request.contextPath}/reservation">別の条件を入力する</a></div>
<p class="hint">ローカル管理画面: /admin/reservations（同じPCからのみアクセス可能）</p>
</main><footer class="reservation-footer">&copy; 夢屋旅館 学習用デモ</footer></body></html>
