package jp.portfolio.yumeya;

import static org.junit.jupiter.api.Assertions.*;
import org.junit.jupiter.api.Test;

class LocalAdminAccessTest {
    @Test void acceptsLoopback() {
        assertTrue(LocalAdminAccess.allowed("127.0.0.1"));
        assertTrue(LocalAdminAccess.allowed("::1"));
    }
    @Test void rejectsNonLoopback() {
        assertFalse(LocalAdminAccess.allowed("192.168.1.10"));
        assertFalse(LocalAdminAccess.allowed("8.8.8.8"));
        assertFalse(LocalAdminAccess.allowed((String) null));
    }
}
