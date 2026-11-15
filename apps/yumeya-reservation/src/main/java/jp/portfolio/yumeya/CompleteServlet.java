package jp.portfolio.yumeya;

import java.io.IOException;
import java.sql.SQLException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/reservation/complete")
public class CompleteServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private final ReservationRepository repository = new ReservationRepository();

    @Override protected void doPost(HttpServletRequest request, HttpServletResponse response)
        throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setHeader("Cache-Control", "no-store");
        if (!SessionProtection.isValid(request)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "操作をやり直してください。");
            return;
        }
        HttpSession session = request.getSession(false);
        ReservationDraft pending = (ReservationDraft) session.getAttribute("pendingReservation");
        if (pending == null) {
            response.sendRedirect(request.getContextPath() + "/reservation");
            return;
        }
        try {
            long id = repository.insert(pending);
            // PRG avoids browser reload resubmitting the INSERT; no personal data is collected.
            session.removeAttribute("pendingReservation");
            session.setAttribute("lastSavedReservationId", id);
            response.sendRedirect(request.getContextPath() + "/reservation/complete");
        } catch (ReservationRepository.AlreadyBookedException e) {
            request.setAttribute("reservation", pending);
            request.setAttribute("csrfToken", SessionProtection.token(session));
            request.setAttribute("errorMessage", "この日程は既に架空の予約が登録されています。別の日程を選んでください。");
            request.getRequestDispatcher("/WEB-INF/views/confirm.jsp").forward(request, response);
        } catch (SQLException e) {
            getServletContext().log("デモ予約のDB保存に失敗", e);
            response.sendError(HttpServletResponse.SC_SERVICE_UNAVAILABLE,
                "デモDBに接続できません。PostgreSQLと環境変数を確認してください。");
        }
    }

    @Override protected void doGet(HttpServletRequest request, HttpServletResponse response)
        throws ServletException, IOException {
        response.setHeader("Cache-Control", "no-store");
        HttpSession session = request.getSession(false);
        Long id = session == null ? null : (Long) session.getAttribute("lastSavedReservationId");
        if (id == null) {
            response.sendRedirect(request.getContextPath() + "/reservation");
            return;
        }
        try {
            ReservationRecord saved = repository.find(id);
            if (saved == null) {
                response.sendRedirect(request.getContextPath() + "/reservation");
                return;
            }
            request.setAttribute("saved", saved);
            request.getRequestDispatcher("/WEB-INF/views/complete.jsp").forward(request, response);
        } catch (SQLException e) {
            getServletContext().log("登録済みデモ予約の取得に失敗", e);
            response.sendError(HttpServletResponse.SC_SERVICE_UNAVAILABLE,
                "デモDBに接続できません。");
        }
    }
}
