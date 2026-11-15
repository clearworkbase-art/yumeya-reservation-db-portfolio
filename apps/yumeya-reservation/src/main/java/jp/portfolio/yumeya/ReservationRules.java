package jp.portfolio.yumeya;

import java.time.Clock;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.Map;

/** Validates user input independently of Servlet, making the rules easy to test. */
public final class ReservationRules {
    private static final Map<String, String> ROOMS = Map.of(
        "MATSU", "桂松の間", "TAKE", "梧竹の間", "UME", "梅響の間"
    );
    private ReservationRules() {}

    public static Result evaluate(String room, String checkIn, String checkOut, String guestCount, Clock clock) {
        if (!ROOMS.containsKey(room)) return Result.error("客室を選択してください。");
        if (checkIn == null || checkOut == null) return Result.error("宿泊日を入力してください。");
        final LocalDate start;
        final LocalDate end;
        try {
            start = LocalDate.parse(checkIn);
            end = LocalDate.parse(checkOut);
        } catch (DateTimeParseException e) {
            return Result.error("宿泊日を正しく入力してください。");
        }
        LocalDate today = LocalDate.now(clock);
        if (start.isBefore(today)) return Result.error("チェックインには今日以降の日付を指定してください。");
        if (start.isAfter(today.plusYears(1))) return Result.error("チェックインは1年以内の日付を指定してください。");
        if (!end.isAfter(start)) return Result.error("チェックアウトはチェックインより後の日付を指定してください。");
        if (end.isAfter(start.plusDays(14))) return Result.error("このデモで選べるのは14泊までです。");
        final int guests;
        try {
            guests = Integer.parseInt(guestCount);
        } catch (NumberFormatException e) {
            return Result.error("宿泊人数を選択してください。");
        }
        if (guests < 1 || guests > 4) return Result.error("宿泊人数は1〜4名で選択してください。");
        return Result.success(new ReservationDraft(room, ROOMS.get(room), start, end, guests));
    }

    public static final class Result {
        private final ReservationDraft draft;
        private final String errorMessage;
        private Result(ReservationDraft draft, String errorMessage) {
            this.draft = draft;
            this.errorMessage = errorMessage;
        }
        static Result error(String errorMessage) { return new Result(null, errorMessage); }
        static Result success(ReservationDraft draft) { return new Result(draft, null); }
        public boolean isValid() { return draft != null; }
        public ReservationDraft getDraft() { return draft; }
        public String getErrorMessage() { return errorMessage; }
    }
}
