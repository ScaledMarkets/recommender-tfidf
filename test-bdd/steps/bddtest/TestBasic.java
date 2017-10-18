package bddtest;

import scaledmarkets.recommenders.messages.Messages.Message;
import scaledmarkets.recommenders.messages.Messages.NoRecommendationMessage;
import scaledmarkets.recommenders.messages.Messages.RecommendationMessage;

import cucumber.api.Format;
import cucumber.api.java.Before;
import cucumber.api.java.After;
import cucumber.api.java.en.Given;
import cucumber.api.java.en.Then;
import cucumber.api.java.en.When;

import com.google.gson.Gson;
import com.google.gson.JsonSyntaxException;

import org.apache.mahout.cf.taste.recommender.RecommendedItem;
import org.apache.mahout.cf.taste.impl.model.jdbc.MySQLJDBCDataModel;
import org.apache.mahout.cf.taste.model.DataModel;

import java.io.File;
import java.io.PrintWriter;
import java.util.List;
import java.util.LinkedList;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.Statement;

import com.mysql.cj.jdbc.MysqlDataSource;

import javax.ws.rs.client.Client;
import javax.ws.rs.client.ClientBuilder;
import javax.ws.rs.core.Response;
import javax.ws.rs.client.WebTarget;

public class TestBasic extends TestBase {
	
	private DataModel model;
	private List<RecommendedItem> recommendations;
	
	/*
	 * MySql command reference:
	 *	http://www.pantz.org/software/mysql/mysqlcommands.html
	 */
	@Given("^four users and their item preferences in a database$")
	public void four_users_and_their_item_preferences_in_a_database() throws Exception {
		
		MysqlDataSource dataSource = new MysqlDataSource();
		//ConnectionPoolDataSource dataSource = new MysqlConnectionPoolDataSource();
		dataSource.setUser("root");
		dataSource.setPassword("test");
		dataSource.setServerName("127.0.0.1");
		dataSource.setPort(3306);
		dataSource.setDatabaseName("test");

		// Clear database and populate it.
		Connection con = null;
		Statement stmt = null;
		try {
			con = dataSource.getConnection();
			stmt = con.createStatement();
			
			// User 1
			stmt.executeUpdate("DELETE FROM UserPrefs WHERE UserID = *");
			stmt.executeUpdate("INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (1,10,1.0)");
			stmt.executeUpdate("INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (1,11,2.0)");
			stmt.executeUpdate("INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (1,12,5.0)");
			stmt.executeUpdate("INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (1,13,5.0)");
			stmt.executeUpdate("INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (1,14,5.0)");
			stmt.executeUpdate("INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (1,15,4.0)");
			stmt.executeUpdate("INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (1,16,5.0)");
			stmt.executeUpdate("INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (1,17,1.0)");
			stmt.executeUpdate("INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (1,18,5.0)");
			
			// User 2
			stmt.executeUpdate("INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (2,10,1.0)");
			stmt.executeUpdate("INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (2,11,2.0)");
			stmt.executeUpdate("INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (2,15,5.0)");
			stmt.executeUpdate("INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (2,16,4.5)");
			stmt.executeUpdate("INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (2,17,1.0)");
			stmt.executeUpdate("INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (2,18,5.0)");
			
			// User 3
			stmt.executeUpdate("INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (3,11,2.5)");
			stmt.executeUpdate("INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (3,12,4.5)");
			stmt.executeUpdate("INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (3,13,4.0)");
			stmt.executeUpdate("INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (3,14,3.0)");
			stmt.executeUpdate("INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (3,15,3.5)");
			stmt.executeUpdate("INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (3,16,4.5)");
			stmt.executeUpdate("INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (3,17,4.0)");
			stmt.executeUpdate("INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (3,18,5.0)");
			
			// User 4
			stmt.executeUpdate("INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (4,10,5.0)");
			stmt.executeUpdate("INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (4,11,5.0)");
			stmt.executeUpdate("INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (4,12,5.0)");
			stmt.executeUpdate("INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (4,13,0.0)");
			stmt.executeUpdate("INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (4,14,2.0)");
			stmt.executeUpdate("INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (4,15,3.0)");
			stmt.executeUpdate("INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (4,16,1.0)");
			stmt.executeUpdate("INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (4,17,4.0)");
			stmt.executeUpdate("INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (4,18,1.0)");
		} finally {
			if(stmt != null) stmt.close();
			if(con != null) con.close();
		}
		
		// Connect mahout to database.
		this.model = new MySQLJDBCDataModel(dataSource,
			"UserPrefs",
			"UserID",
			"ItemID",
			"Preference",
			null);
	}
	
	@When("^I remotely request a recommendation for a user$")
	public void i_remotely_request_a_recommendation_for_a_user() throws Exception {
		
		// Re-initialize the expected result container.
		this.recommendations = new LinkedList<RecommendedItem>();
		
		// Make remote GET request, and verify the JSON response.
		Client client = ClientBuilder.newClient();
		WebTarget target = client.target("http://127.0.0.1:3306/recommend");
		Response response = target.request("application/json").get();
		if (response.getStatus() >= 300) {
			throw new Exception(response.getStatusInfo().getReasonPhrase());
		}
		String output = response.readEntity(String.class);
		
		// Parse JSON.
		Gson gson = new Gson();
		RecommendedItem rec = null;
		try {
			NoRecommendationMessage noRefMsg;
			noRefMsg = gson.fromJson(output, NoRecommendationMessage.class);
			// There are no recommendations.
		} catch (JsonSyntaxException ex) {
			try {
				RecommendationMessage recMsg = gson.fromJson(output, RecommendationMessage.class);
				rec = new LocalRecommendation(recMsg.itemID, recMsg.value);
				this.recommendations.add(rec);
			} catch (JsonSyntaxException ex2) {
				throw new Exception(
					"Message from server is an unexpected type. Json=" + output);
			}
		}
	}
	
	static class LocalRecommendation implements RecommendedItem {
		LocalRecommendation(long itemID, float value) {
			this.itemID = itemID; this.value = value;
		}
		private long itemID;
		private float value;
		public long getItemID() { return this.itemID; }
		public float getValue() { return this.value; }
	}
	
	@Then("^I obtain one recommendation$")
	public void i_obtain_one_recommendation() throws Exception {
		assertThat(this.recommendations.size() == 1, "Expected items to have 1" +
			" elements, but it has " + this.recommendations.size());
	}
}
