package jp.portfolio.yumeya;

import java.io.IOException;
import java.sql.SQLException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/admin/reservations/cancel")
public class CancelReservationServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final ReservationRepository repository = new ReservationRepository();
    @Override protected void doPost(HttpServletRequest request, HttpServletResponse response)
        throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setHeader("Cache-Control", "no-store");
        if (!LocalAdminAccess.allowed(request) || !SessionProtection.isValid(request)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN);
            return;
        }
        try {
            long id = Long.parseLong(request.getParameter("id"));
            if (id <= 0) throw new NumberFormatException("id<=0");
            boolean changed = repository.cancel(id);
            response.sendRedirect(request.getContextPath() + "/admin/reservations?cancelled=" + (changed ? "1" : "0"));
        } catch (NumberFormatException e) {
            response.sendError(HttpServletResponse.SC_BAD_REQUEST, "IDを確認してください。");
        } catch (SQLException e) {
            getServletContext().log("デモ予約の取消処理に失敗", e);
            response.sendError(HttpServletResponse.SC_SERVICE_UNAVAILABLE, "デモDBに接続できません。");
        }
    }
}
