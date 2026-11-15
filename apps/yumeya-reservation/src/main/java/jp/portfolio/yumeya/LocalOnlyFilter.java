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

/** Local demo only. IP checks are NOT a substitute for production authentication. */
@WebFilter(urlPatterns = {"/reservation", "/reservation/*", "/admin/*"})
public final class LocalOnlyFilter implements Filter {
    @Override public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
        throws IOException, ServletException {
        HttpServletRequest http = (HttpServletRequest) request;
        if (!LocalAdminAccess.allowed(http.getRemoteAddr())) {
            ((HttpServletResponse) response).sendError(HttpServletResponse.SC_FORBIDDEN,
                "DB機能はローカルPCでのみ実行できます。");
            return;
        }
        chain.doFilter(request, response);
    }
}
