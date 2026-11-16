package jp.portfolio.yumeya;

import java.io.IOException;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/** Lightweight in-process write cap for the public portfolio demo, not a production WAF. */
@WebFilter(urlPatterns = "/reservation/complete")
public final class PublicDemoWriteLimitFilter implements Filter {
    private static final int MAX_POSTS_PER_HOUR = 30;
    private Instant windowStart = Instant.now();
    private int postCount = 0;

    // One shared cap avoids depending on easily spoofed client-address headers.
    private synchronized boolean tryConsume() {
        Instant now = Instant.now(Clock.systemUTC());
        if (Duration.between(windowStart, now).toHours() >= 1) {
            windowStart = now;
            postCount = 0;
        }
        if (postCount >= MAX_POSTS_PER_HOUR) return false;
        postCount++;
        return true;
    }

    @Override public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
        throws IOException, ServletException {
        HttpServletRequest request = (HttpServletRequest) req;
        HttpServletResponse response = (HttpServletResponse) res;
        if ("true".equalsIgnoreCase(System.getenv("YUMEYA_PUBLIC_DEMO"))
            && "POST".equalsIgnoreCase(request.getMethod()) && !tryConsume()) {
            response.setHeader("Retry-After", "3600");
            response.sendError(429, "デモの登録回数が上限に達しました。時間をおいてお試しください。");
            return;
        }
        chain.doFilter(req, res);
    }
}
