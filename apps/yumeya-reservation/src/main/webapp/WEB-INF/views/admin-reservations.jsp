<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<!DOCTYPE html><html lang="ja"><head>
<meta name="robots" content="noindex, nofollow">
<meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>架空予約データ管理｜夢屋旅館</title>
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/common/reset.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/common/common.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/page/reservation.css">
</head><body>
<div class="portfolio-demo-banner" role="note"><strong>架空の施設・学習専用</strong>｜管理画面はローカル閲覧限定です。公開サーバーでの利用は禁止です。</div>
<header class="reservation-header"><a href="${pageContext.request.contextPath}/index.html">銀山温泉 夢屋旅館</a><span>データ管理（ローカルのみ）</span></header>
<main class="reservation-container admin-wide">
<p class="eyebrow">SQL · JOIN · UPDATE · JDBC</p><h1>架空予約データ一覧</h1>
<p class="demo-notice">PostgreSQLの <code>rooms</code> と <code>reservations</code> をJOINし、条件検索と状態更新を確認する学習ページです。最大100件表示します。</p>
<c:if test="${cancelled}"><p class="demo-notice">取消状態に更新しました。</p></c:if>
<form class="filter-form" method="get" action="${pageContext.request.contextPath}/admin/reservations">
<label>客室 <select name="room">
<option value="">すべて</option>
<option value="MATSU" ${filterRoom eq 'MATSU' ? 'selected' : ''}>桂松の間</option>
<option value="TAKE" ${filterRoom eq 'TAKE' ? 'selected' : ''}>梧竹の間</option>
<option value="UME" ${filterRoom eq 'UME' ? 'selected' : ''}>梅響の間</option>
</select></label>
<label>状態 <select name="status">
<option value="">すべて</option>
<option value="CONFIRMED" ${filterStatus eq 'CONFIRMED' ? 'selected' : ''}>登録済</option>
<option value="CANCELLED" ${filterStatus eq 'CANCELLED' ? 'selected' : ''}>取消済</option>
</select></label><button type="submit">検索</button></form>
<div class="table-wrap"><table class="admin-table"><thead><tr>
<th>ID</th><th>客室</th><th>入室日</th><th>退室日</th><th>人数</th><th>状態</th><th>操作</th>
</tr></thead><tbody>
<c:forEach var="r" items="${rows}"><tr>
<td><c:out value="${r.id}"/></td><td><c:out value="${r.roomLabel}"/></td>
<td><c:out value="${r.checkIn}"/></td><td><c:out value="${r.checkOut}"/></td>
<td><c:out value="${r.guests}"/>名</td><td><c:out value="${r.statusLabel}"/></td><td>
<c:if test="${r.status eq 'CONFIRMED'}">
<form method="post" action="${pageContext.request.contextPath}/admin/reservations/cancel">
<input type="hidden" name="id" value="${r.id}"><input type="hidden" name="csrfToken" value="${csrfToken}">
<button type="submit" class="small-button">架空予約を取消</button></form>
</c:if></td></tr></c:forEach>
<c:if test="${empty rows}"><tr><td colspan="7">該当する架空データはありません。</td></tr></c:if>
</tbody></table></div>
<div class="actions"><a class="text-link" href="${pageContext.request.contextPath}/reservation">条件入力へ</a></div>
</main><footer class="reservation-footer">&copy; 夢屋旅館 DB学習用デモ</footer>
</body></html>
