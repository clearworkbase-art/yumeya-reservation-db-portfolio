package jp.portfolio.yumeya;

import java.io.IOException;
import java.time.Clock;
import java.time.LocalDate;
import java.time.ZoneId;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/reservation/confirm")
public class ConfirmServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    @Override protected void doPost(HttpServletRequest request, HttpServletResponse response)
        throws ServletException, IOException {
        request.setCharacterEncoding("UTF-8");
        response.setHeader("Cache-Control", "no-store");
        if (!SessionProtection.isValid(request)) {
            response.sendError(HttpServletResponse.SC_FORBIDDEN, "操作をやり直してください。");
            return;
        }
        HttpSession session = request.getSession(false);
        session.removeAttribute("pendingReservation");
        ReservationRules.Result result = ReservationRules.evaluate(
            request.getParameter("room"), request.getParameter("checkIn"),
            request.getParameter("checkOut"), request.getParameter("guests"),
            Clock.system(ZoneId.of("Asia/Tokyo"))
        );
        request.setAttribute("csrfToken", SessionProtection.token(session));
        if (!result.isValid()) {
            request.setAttribute("today", LocalDate.now(ZoneId.of("Asia/Tokyo")).toString());
            request.setAttribute("errorMessage", result.getErrorMessage());
            request.getRequestDispatcher("/WEB-INF/views/reservation.jsp").forward(request, response);
            return;
        }
        session.setAttribute("pendingReservation", result.getDraft());
        request.setAttribute("reservation", result.getDraft());
        request.getRequestDispatcher("/WEB-INF/views/confirm.jsp").forward(request, response);
    }
}
