package jp.portfolio.yumeya;

import javax.servlet.http.HttpServletRequest;

/** Demonstration only: restrict admin pages to direct loopback requests. Not production auth. */
public final class LocalAdminAccess {
    private LocalAdminAccess() { }
    public static boolean allowed(String remoteAddress) {
        return "127.0.0.1".equals(remoteAddress)
            || "0:0:0:0:0:0:0:1".equals(remoteAddress)
            || "::1".equals(remoteAddress);
    }
    public static boolean allowed(HttpServletRequest request) {
        return allowed(request.getRemoteAddr());
    }
}
