package jp.portfolio.yumeya;

import java.io.Serializable;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

/** Validated values held in the HTTP session until demo registration in PostgreSQL. */
public final class ReservationDraft implements Serializable {
    private static final long serialVersionUID = 1L;
    private final String roomCode;
    private final String roomLabel;
    private final LocalDate checkIn;
    private final LocalDate checkOut;
    private final int guests;

    public ReservationDraft(String roomCode, String roomLabel, LocalDate checkIn, LocalDate checkOut, int guests) {
        this.roomCode = roomCode;
        this.roomLabel = roomLabel;
        this.checkIn = checkIn;
        this.checkOut = checkOut;
        this.guests = guests;
    }
    public String getRoomCode() { return roomCode; }
    public String getRoomLabel() { return roomLabel; }
    public String getCheckIn() { return checkIn.toString(); }
    public String getCheckOut() { return checkOut.toString(); }
    public int getGuests() { return guests; }
    public long getNights() { return ChronoUnit.DAYS.between(checkIn, checkOut); }
}
