package jp.portfolio.yumeya;

import java.security.SecureRandom;
import java.util.Base64;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

/** Same-session CSRF token required by each state-changing form. */
public final class SessionProtection {
    static final String TOKEN_ATTRIBUTE = "csrfToken";
    private static final SecureRandom RANDOM = new SecureRandom();
    private SessionProtection() {}
    public static String token(HttpSession session) {
        String token = (String) session.getAttribute(TOKEN_ATTRIBUTE);
        if (token == null) {
            byte[] bytes = new byte[32];
            RANDOM.nextBytes(bytes);
            token = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
            session.setAttribute(TOKEN_ATTRIBUTE, token);
        }
        return token;
    }
    public static boolean isValid(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        return session != null && token(session).equals(request.getParameter("csrfToken"));
    }
}
