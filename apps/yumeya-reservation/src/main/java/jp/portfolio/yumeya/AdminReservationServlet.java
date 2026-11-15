package jp.portfolio.yumeya;

import java.io.IOException;
import java.sql.SQLException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/** Local machine only. Requires real authentication/authorization before public deployment. */
@WebServlet("/admin/reservations")
public class AdminReservationServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final ReservationRepository repository = new ReservationRepository();

    @Override protected void doGet(HttpServletRequest request, HttpServletResponse response)
        throws ServletException, IOException {
        response.setHeader("Cache-Control", "no-store");
        if (!LocalAdminAccess.allowed(request)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "管理画面はローカル限定です。");
            return;
        }
        String room = request.getParameter("room");
        String status = request.getParameter("status");
        if (!("MATSU".equals(room) || "TAKE".equals(room) || "UME".equals(room))) room = "";
        if (!("CONFIRMED".equals(status) || "CANCELLED".equals(status))) status = "";
        try {
            HttpSession session = request.getSession(true);
            request.setAttribute("csrfToken", SessionProtection.token(session));
            request.setAttribute("rows", repository.search(room, status));
            request.setAttribute("filterRoom", room);
            request.setAttribute("filterStatus", status);
            request.setAttribute("cancelled", "1".equals(request.getParameter("cancelled")));
            request.getRequestDispatcher("/WEB-INF/views/admin-reservations.jsp").forward(request, response);
        } catch (SQLException e) {
            getServletContext().log("管理画面でDBの検索に失敗", e);
            response.sendError(HttpServletResponse.SC_SERVICE_UNAVAILABLE,
                "デモDBに接続できません。PostgreSQLと環境変数を確認してください。");
        }
    }
}
