package jp.portfolio.yumeya;

import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;
import javax.servlet.SessionCookieConfig;
import javax.servlet.annotation.WebListener;

/** HTTPS-only browser session cookie in cloud mode; local HTTP stays usable. */
@WebListener
public final class PublicDemoSessionCookie implements ServletContextListener {
    @Override public void contextInitialized(ServletContextEvent event) {
        if ("true".equalsIgnoreCase(System.getenv("YUMEYA_PUBLIC_DEMO"))) {
            SessionCookieConfig cookie = event.getServletContext().getSessionCookieConfig();
            cookie.setHttpOnly(true);
            cookie.setSecure(true);
        }
    }
    @Override public void contextDestroyed(ServletContextEvent event) { }
}
