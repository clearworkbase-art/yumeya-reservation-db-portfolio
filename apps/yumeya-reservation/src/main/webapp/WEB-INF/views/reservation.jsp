<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="ja">
<head>
        <meta name="robots" content="noindex, nofollow">
<meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>宿泊予約デモ｜銀山温泉 夢屋旅館</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/common/reset.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/common/common.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/page/reservation.css">
</head>
<body>
    <div class="portfolio-demo-banner" role="note"><strong>架空の旅館・ポートフォリオ作品</strong> ｜ Java Servlet/JSPの学習用デモです。実在の施設ではなく、宿泊予約・電話受付・アクセス案内は行っていません。</div>

<header class="reservation-header"><a href="${pageContext.request.contextPath}/index.html">銀山温泉 夢屋旅館</a><span>宿泊予約デモ</span></header>
<main class="reservation-container">
    <p class="eyebrow">RESERVATION SYSTEM · JAVA SERVLET / JSP</p>
    <h1>ご宿泊内容の入力</h1>
    <p class="demo-notice"><strong>ポートフォリオ用デモ</strong>です。実際の宿泊予約・空室照会・決済は行われません。確認画面の次に「デモ予約をDBに保存」を押すと、架空の入力データをローカルPostgreSQLへ保存します。氏名・連絡先は収集しません。</p>
    <ol class="steps"><li class="current">1. 条件入力</li><li>2. 内容確認</li><li>3. デモ完了</li></ol>
    <%-- Error messages are authored on the server, never echoed from user input. --%>
    <p class="error" role="alert" ${empty errorMessage ? 'hidden' : ''}>${errorMessage}</p>
    <form class="reservation-form" action="${pageContext.request.contextPath}/reservation/confirm" method="post">
        <input type="hidden" name="csrfToken" value="${csrfToken}">
        <fieldset><legend>客室を選択</legend>
            <label class="field"><span>客室</span><select name="room" required>
                <option value="">選択してください</option>
                <option value="MATSU">桂松の間</option>
                <option value="TAKE">梧竹の間</option>
                <option value="UME">梅響の間</option>
            </select></label>
            <p class="hint">客室は既存の旅館サイトに掲載された3室を使用しています。料金データは未連携です。DB登録時に同室・重複日程を拒否します。</p>
        </fieldset>
        <fieldset><legend>宿泊日程</legend><div class="field-grid">
            <label class="field"><span>チェックイン</span><input type="date" name="checkIn" min="${today}" required></label>
            <label class="field"><span>チェックアウト</span><input type="date" name="checkOut" min="${today}" required></label>
        </div></fieldset>
        <fieldset><legend>人数</legend><label class="field"><span>大人（1〜4名）</span>
            <select name="guests" required><option value="1">1名</option><option value="2" selected>2名</option><option value="3">3名</option><option value="4">4名</option></select>
        </label></fieldset>
        <div class="actions"><a class="text-link" href="${pageContext.request.contextPath}/u_room/index.html">客室ページへ戻る</a><button type="submit">入力内容を確認</button></div>
    </form>
</main>
<footer class="reservation-footer">&copy; 夢屋旅館 Webアプリ学習用デモ｜実際の予約受付ではありません</footer>
</body></html>
