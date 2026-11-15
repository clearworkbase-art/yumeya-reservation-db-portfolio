package jp.portfolio.yumeya;

import static org.junit.jupiter.api.Assertions.*;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import org.junit.jupiter.api.Test;

class ReservationRulesJUnitTest {
    private final Clock clock = Clock.fixed(Instant.parse("2026-11-13T15:00:00Z"), ZoneId.of("Asia/Tokyo"));

    @Test void acceptsCorrectStay() {
        var r = ReservationRules.evaluate("MATSU", "2026-11-19", "2026-11-20", "2", clock);
        assertTrue(r.isValid());
        assertEquals(1, r.getDraft().getNights());
        assertEquals("桂松の間", r.getDraft().getRoomLabel());
    }
    @Test void rejectsCheckoutBeforeCheckin() {
        var r = ReservationRules.evaluate("MATSU", "2026-11-20", "2026-11-19", "2", clock);
        assertFalse(r.isValid());
    }
    @Test void rejectsGuestCountAboveLimit() {
        var r = ReservationRules.evaluate("TAKE", "2026-11-19", "2026-11-20", "5", clock);
        assertFalse(r.isValid());
    }
    @Test void rejectsInvalidRoomCode() {
        var r = ReservationRules.evaluate("UNKNOWN", "2026-11-19", "2026-11-20", "2", clock);
        assertFalse(r.isValid());
    }
    @Test void allowsAdjacentStayDateWindow() {
        var r = ReservationRules.evaluate("UME", "2026-11-20", "2026-11-21", "1", clock);
        assertTrue(r.isValid());
    }
}
