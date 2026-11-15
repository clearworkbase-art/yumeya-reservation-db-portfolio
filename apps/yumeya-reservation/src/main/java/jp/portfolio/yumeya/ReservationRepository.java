package jp.portfolio.yumeya;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/** JDBC-only DAO. All values are passed through PreparedStatement parameters. */
public final class ReservationRepository {
    public long insert(ReservationDraft draft) throws SQLException, AlreadyBookedException {
        final String sql = "INSERT INTO reservations (room_code, check_in, check_out, guests, status) "
            + "VALUES (?, ?, ?, ?, 'CONFIRMED') RETURNING reservation_id";
        try (Connection connection = DbConnection.open();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setString(1, draft.getRoomCode());
            statement.setDate(2, Date.valueOf(draft.getCheckIn()));
            statement.setDate(3, Date.valueOf(draft.getCheckOut()));
            statement.setInt(4, draft.getGuests());
            try (ResultSet rs = statement.executeQuery()) {
                if (!rs.next()) throw new SQLException("登録IDを取得できませんでした。");
                return rs.getLong(1);
            }
        } catch (SQLException e) {
            // PostgreSQL exclusion_violation: two active bookings overlap for the same room.
            if ("23P01".equals(e.getSQLState())) throw new AlreadyBookedException(e);
            throw e;
        }
    }

    public ReservationRecord find(long id) throws SQLException {
        String sql = "SELECT r.reservation_id, r.room_code, m.room_name, r.check_in, r.check_out, "
            + "r.guests, r.status FROM reservations r "
            + "JOIN rooms m ON m.room_code = r.room_code WHERE r.reservation_id = ?";
        try (Connection connection = DbConnection.open();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setLong(1, id);
            try (ResultSet rs = statement.executeQuery()) {
                return rs.next() ? map(rs) : null;
            }
        }
    }

    /** Search is restricted to the first 100 records for the local demo UI. */
    public List<ReservationRecord> search(String roomCode, String status) throws SQLException {
        StringBuilder sql = new StringBuilder(
            "SELECT r.reservation_id, r.room_code, m.room_name, r.check_in, r.check_out, "
          + "r.guests, r.status FROM reservations r JOIN rooms m ON m.room_code = r.room_code WHERE 1=1");
        List<String> parameters = new ArrayList<>();
        if (roomCode != null && !roomCode.isEmpty()) {
            sql.append(" AND r.room_code = ?");
            parameters.add(roomCode);
        }
        if (status != null && !status.isEmpty()) {
            sql.append(" AND r.status = ?");
            parameters.add(status);
        }
        sql.append(" ORDER BY r.created_at DESC, r.reservation_id DESC LIMIT 100");
        try (Connection connection = DbConnection.open();
             PreparedStatement statement = connection.prepareStatement(sql.toString())) {
            for (int i = 0; i < parameters.size(); i++) statement.setString(i + 1, parameters.get(i));
            try (ResultSet rs = statement.executeQuery()) {
                List<ReservationRecord> rows = new ArrayList<>();
                while (rs.next()) rows.add(map(rs));
                return rows;
            }
        }
    }

    /** Mark cancelled; never delete the row so the state transition remains traceable. */
    public boolean cancel(long id) throws SQLException {
        String sql = "UPDATE reservations SET status = 'CANCELLED', cancelled_at = CURRENT_TIMESTAMP "
                   + "WHERE reservation_id = ? AND status = 'CONFIRMED'";
        try (Connection connection = DbConnection.open();
             PreparedStatement statement = connection.prepareStatement(sql)) {
            statement.setLong(1, id);
            return statement.executeUpdate() == 1;
        }
    }

    private static ReservationRecord map(ResultSet rs) throws SQLException {
        LocalDate in = rs.getDate("check_in").toLocalDate();
        LocalDate out = rs.getDate("check_out").toLocalDate();
        return new ReservationRecord(rs.getLong("reservation_id"), rs.getString("room_code"),
            rs.getString("room_name"), in, out, rs.getInt("guests"), rs.getString("status"));
    }

    public static final class AlreadyBookedException extends Exception {
        private static final long serialVersionUID = 1L;
        AlreadyBookedException(Throwable cause) { super("既に同じ客室に重複したデモ予約があります。", cause); }
    }
}
