package bddtest;

import java.io.File;
import java.io.PrintWriter;
import java.util.List;
import java.util.LinkedList;

import java.sql.Connection;
import java.sql.Statement;

import com.mysql.jdbc.jdbc2.optional.MysqlConnectionPoolDataSource;

public class PopulateForTest {
	
	/*
	 * MySql command reference:
	 *	http://www.pantz.org/software/mysql/mysqlcommands.html
	 *	On Mac, mysql shell is at /usr/local/mysql-shell/bin/mysqlsh
	 *		alias mysql=/usr/local/mysql-shell/bin/mysqlsh
	 */
	public static void main(String[] args) throws Exception {
		
		MysqlConnectionPoolDataSource dataSource = new MysqlConnectionPoolDataSource();
		dataSource.setServerName("127.0.0.1");
		dataSource.setPort(3306);
		dataSource.setDatabaseName("test");
		dataSource.setUser("root");
		dataSource.setPassword("test");

		// Clear database and populate it.
		Connection con = null;
		Statement stmt = null;
		try {
			con = dataSource.getConnection();
			
			try {
				stmt = con.createStatement();
				stmt.executeUpdate("DROP TABLE `UserPrefs`");
			} catch (Exception ex) {
				
			}
			
			stmt = con.createStatement();
			stmt.executeUpdate(
				"CREATE TABLE UserPrefs (" +
				"UserID BIGINT NOT NULL, " +
				"ItemID BIGINT NOT NULL, " +
				"Preference FLOAT NOT NULL, " +
				"PRIMARY KEY (UserID, ItemID), " +
				"INDEX (UserID), " +
				"INDEX (ItemID))");
				
			Object[][] data = {
			
				{1,100,3.5},
				{1,101,2.8},
				{1,105,1.1},
				{1,115,3.4},
			
				{2,100,3.5},
				{2,101,2.8},
				{2,105,1.1},
				{2,115,3.4},
			
				{3,100,3.5},
				{3,101,2.8},
				{3,105,1.1},
				{3,115,3.4},
			
				{4,100,3.5},
				{4,101,2.8},
				{4,105,1.1},
				{4,115,3.4},
			
				{5,100,3.5},
				{5,101,2.8},
				{5,105,1.1},
				{5,115,3.4},
			
				{6,100,3.5},
				{6,101,2.8},
				{6,105,1.1},
				{6,115,3.4},
			
				{7,100,3.5},
				{7,101,2.8},
				{7,105,1.1},
				{7,115,3.4},
			
				{8,100,3.5},
				{8,101,2.8},
				{8,105,1.1},
				{8,115,3.4},
			
				{9,100,3.5},
				{9,101,2.8},
				{9,105,1.1},
				{9,115,3.4},
			
				{10,100,3.5},
				{10,101,2.8}
			
			};
			
			stmt = con.createStatement();
			insertIntoUserPrefs(stmt, data);
			
		} finally {
			if(stmt != null) stmt.close();
			if(con != null) con.close();
		}
	}
	
	protected static void insertIntoUserPrefs(Statement stmt, Object[][] data) throws Exception {
		
		for (Object[] row : data) {
			stmt.executeUpdate(String.format(
				"INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (%d,%d,%f)",
				row[0], row[1], row[2]));
		}
	}
}
