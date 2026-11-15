package jp.portfolio.yumeya;

import java.io.IOException;
import java.time.LocalDate;
import java.time.ZoneId;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/reservation")
public class ReservationServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    @Override protected void doGet(HttpServletRequest request, HttpServletResponse response)
        throws ServletException, IOException {
        response.setHeader("Cache-Control", "no-store");
        HttpSession session = request.getSession(true);
        request.setAttribute("csrfToken", SessionProtection.token(session));
        request.setAttribute("today", LocalDate.now(ZoneId.of("Asia/Tokyo")).toString());
        request.getRequestDispatcher("/WEB-INF/views/reservation.jsp").forward(request, response);
    }
}
