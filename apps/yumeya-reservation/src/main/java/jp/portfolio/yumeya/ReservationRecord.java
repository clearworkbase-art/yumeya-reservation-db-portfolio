package jp.portfolio.yumeya;

import java.time.LocalDate;

/** Row returned by a join between reservations and rooms. */
public final class ReservationRecord {
    private final long id;
    private final String roomCode;
    private final String roomLabel;
    private final LocalDate checkIn;
    private final LocalDate checkOut;
    private final int guests;
    private final String status;

    public ReservationRecord(long id, String roomCode, String roomLabel, LocalDate checkIn,
                             LocalDate checkOut, int guests, String status) {
        this.id = id;
        this.roomCode = roomCode;
        this.roomLabel = roomLabel;
        this.checkIn = checkIn;
        this.checkOut = checkOut;
        this.guests = guests;
        this.status = status;
    }
    public long getId() { return id; }
    public String getRoomCode() { return roomCode; }
    public String getRoomLabel() { return roomLabel; }
    public String getCheckIn() { return checkIn.toString(); }
    public String getCheckOut() { return checkOut.toString(); }
    public int getGuests() { return guests; }
    public String getStatus() { return status; }
    public String getStatusLabel() { return "CANCELLED".equals(status) ? "取消済" : "登録済"; }
}
