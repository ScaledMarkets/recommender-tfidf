package bddtest;

import com.scaledmarkets.recommenders.messages.Messages.Message;
import com.scaledmarkets.recommenders.messages.Messages.NoRecommendationMessage;
import com.scaledmarkets.recommenders.messages.Messages.RecommendationMessage;

import cucumber.api.Format;
import cucumber.api.java.Before;
import cucumber.api.java.After;
import cucumber.api.java.en.Given;
import cucumber.api.java.en.Then;
import cucumber.api.java.en.When;

import com.google.gson.Gson;
import com.google.gson.JsonSyntaxException;

import java.io.File;
import java.io.PrintWriter;
import java.util.List;
import java.util.LinkedList;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.Statement;

import com.mysql.jdbc.jdbc2.optional.MysqlConnectionPoolDataSource;

import javax.ws.rs.client.Client;
import javax.ws.rs.client.ClientBuilder;
import javax.ws.rs.core.Response;
import javax.ws.rs.client.WebTarget;

public class TestBasic extends TestBase {
	
	private static final String Scheme = "http";
	private static final String Host = "127.0.0.1";
	private static final String Port = "8080";
	
	private List<LocalRecommendation> recommendations;
	
	/*
	 * MySql command reference:
	 *	http://www.pantz.org/software/mysql/mysqlcommands.html
	 */
	@Given("^ten users and identical item preferences in a database$")
	public void ten_users_and_identical_item_preferences_in_a_database() throws Exception {
		
		MysqlConnectionPoolDataSource dataSource = new MysqlConnectionPoolDataSource();
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
			
			stmt.executeUpdate("TRUNCATE TABLE UserPrefs");
			
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
			
				/*
				// User 1
				{1,10,1.0},
				{1,11,2.0},
				{1,12,5.0},
				{1,13,5.0},
				{1,14,5.0},
				{1,15,4.0},
				{1,16,5.0},
				{1,17,1.0},
				{1,18,5.0},
				
				// User 2
				{2,10,1.0},
				{2,11,2.0},
				{2,15,5.0},
				{2,16,4.5},
				{2,17,1.0},
				{2,18,5.0},
				
				// User 3
				{3,11,2.5},
				{3,12,4.5},
				{3,13,4.0},
				{3,14,3.0},
				{3,15,3.5},
				{3,16,4.5},
				{3,17,4.0},
				{3,18,5.0},
				
				// User 4
				{4,10,5.0},
				{4,11,5.0},
				{4,12,5.0},
				{4,13,0.0},
				{4,14,2.0},
				{4,15,3.0},
				{4,16,1.0},
				{4,17,4.0},
				{4,18,1.0},
				*/
			
			};
			
			insertIntoUserPrefs(stmt, data);
			
		} finally {
			if(stmt != null) stmt.close();
			if(con != null) con.close();
		}
	}
	
	@When("^I remotely request a recommendation for user (\\d+) with threshold (\\d+.\\d+)$")
	public void i_remotely_request_a_recommendation_for_user(long userId, double threshold) throws Exception {
		
		// Re-initialize the expected result container.
		this.recommendations = new LinkedList<LocalRecommendation>();
		
		// Prepare remote GET request.
		Client client = ClientBuilder.newClient();
		WebTarget target = client.target(Scheme + "://" + Host + ":" + Port + "/recommend");
		
		// Add query params: threshold, userid.
		target = target.queryParam("userid", String.valueOf(userId));
		
		// Perform remote request.
		Response response = target.request("application/json").get();
		if (response.getStatus() >= 300) {
			System.out.println(response.getStatusInfo().getReasonPhrase());
			throw new Exception(response.getStatusInfo().getReasonPhrase());
		}
		String output = response.readEntity(String.class);
		System.out.println("output: " + output);
		
		// Parse JSON.
		Gson gson = new Gson();
		LocalRecommendation rec = null;
		
		try {
			RecommendationMessage recMsg = gson.fromJson(output, RecommendationMessage.class);
			rec = new LocalRecommendation(recMsg.itemID, recMsg.value);
			this.recommendations.add(rec);
		} catch (JsonSyntaxException ex2) {
			try {
				NoRecommendationMessage noRefMsg;
				noRefMsg = gson.fromJson(output, NoRecommendationMessage.class);
				// There are no recommendations.
			} catch (JsonSyntaxException ex) {
				throw new Exception(
					"Message from server is an unexpected type. Json=" + output);
			}
		}
	}
	
	static class LocalRecommendation {
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
			" element, but it has " + this.recommendations.size());
	}
	
	protected void insertIntoUserPrefs(Statement stmt, Object[][] data) throws Exception {
		
		for (Object[] row : data) {
			stmt.executeUpdate(String.format(
				"INSERT INTO UserPrefs ( UserID, ItemID, Preference ) VALUES (%d,%d,%f)",
				row[0], row[1], row[2]));
		}
	}
}
