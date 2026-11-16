package jp.portfolio.yumeya;

import java.io.IOException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/** Process-only health check; does not imply that the database is reachable. */
@WebServlet("/health")
public final class PublicHealthServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    @Override protected void doGet(HttpServletRequest request, HttpServletResponse response)
        throws IOException {
        response.setContentType("text/plain;charset=UTF-8");
        response.setHeader("Cache-Control", "no-store");
        response.getWriter().println("app ready");
    }
}
