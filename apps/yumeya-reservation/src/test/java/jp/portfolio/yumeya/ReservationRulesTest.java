package jp.portfolio.yumeya;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;

/** Standard Java smoke tests: run without JUnit or a running Tomcat. */
public class ReservationRulesTest {
    private static final Clock CLOCK = Clock.fixed(Instant.parse("2026-11-13T15:00:00Z"), ZoneId.of("Asia/Tokyo"));
    private static int passed = 0;
    public static void main(String[] args) {
        valid("normal", "MATSU", "2026-11-15", "2026-11-16", "2", true);
        valid("same day", "TAKE", "2026-11-15", "2026-11-15", "2", false);
        valid("past date", "UME", "2026-11-13", "2026-11-14", "1", false);
        valid("long stay", "UME", "2026-11-15", "2026-12-15", "2", false);
        valid("unknown room", "BAD", "2026-11-15", "2026-11-16", "1", false);
        valid("too many guests", "MATSU", "2026-11-15", "2026-11-16", "5", false);
        valid("invalid date", "MATSU", "2026-02-30", "2026-03-01", "2", false);
        valid("null guest count", "MATSU", "2026-11-15", "2026-11-16", null, false);
        valid("14 nights", "TAKE", "2026-11-15", "2026-11-29", "4", true);
        valid("over 1yr", "MATSU", "2028-01-01", "2028-01-02", "2", false);
        System.out.println("PASS: " + passed + " rule checks");
    }
    static void valid(String label, String room, String in, String out, String guests, boolean expected) {
        boolean actual = ReservationRules.evaluate(room,in,out,guests,CLOCK).isValid();
        if (actual != expected) throw new AssertionError(label + ": expected=" + expected + " actual=" + actual);
        passed++;
    }
}
