package jp.portfolio.yumeya;

import java.io.IOException;
import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/** In cloud-demo mode, only the public reservation flow is exposed; admin stays disabled. */
@WebFilter(urlPatterns = {"/reservation", "/reservation/*", "/admin/*"})
public final class LocalOnlyFilter implements Filter {
    private static boolean isCloudDemo() {
        return "true".equalsIgnoreCase(System.getenv("YUMEYA_PUBLIC_DEMO"));
    }

    @Override public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
        throws IOException, ServletException {
        HttpServletRequest http = (HttpServletRequest) request;
        HttpServletResponse out = (HttpServletResponse) response;
        String path = http.getRequestURI().substring(http.getContextPath().length());

        if (isCloudDemo()) {
            // Never depend on remoteAddr or proxy forwarding headers to protect the admin UI.
            if (path.startsWith("/admin/") || "/admin".equals(path)) {
                out.sendError(HttpServletResponse.SC_NOT_FOUND);
                return;
            }
            // Existing CSRF and input checks still apply to these public routes.
            if ("/reservation".equals(path) || path.startsWith("/reservation/")) {
                chain.doFilter(request, response);
                return;
            }
        }

        // Local development behavior is unchanged.
        if (!LocalAdminAccess.allowed(http.getRemoteAddr())) {
            out.sendError(HttpServletResponse.SC_FORBIDDEN,
                "DB機能はローカルPCでのみ実行できます。");
            return;
        }
        chain.doFilter(request, response);
    }
}
