package jp.portfolio.yumeya;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/** Database credentials are supplied by environment variables, never committed. */
public final class DbConnection {
    private DbConnection() { }

    public static Connection open() throws SQLException {
        String url = System.getenv("YUMEYA_JDBC_URL");
        String user = System.getenv("YUMEYA_DB_USER");
        String password = System.getenv("YUMEYA_DB_PASSWORD");
        if (isBlank(url) || isBlank(user) || password == null) {
            throw new SQLException("YUMEYA_JDBC_URL / YUMEYA_DB_USER / YUMEYA_DB_PASSWORD を設定してください。");
        }
        if (!url.startsWith("jdbc:postgresql://")) {
            throw new SQLException("このデモは PostgreSQL JDBC URL のみ対応しています。");
        }
        try {
            // TomcatのWebアプリClassLoaderではJDBC 4の自動登録が環境依存になるため、明示的に初期化する。
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            throw new SQLException("PostgreSQL JDBCドライバーがWARに含まれていません。", e);
        }
        return DriverManager.getConnection(url, user, password);
    }

    private static boolean isBlank(String s) { return s == null || s.isBlank(); }
}
