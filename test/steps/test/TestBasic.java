package test;

import scaledmarkets.recommenders.mahout.UserSimilarityRecommender;

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
import org.apache.mahout.cf.taste.model.DataModel;
import org.apache.mahout.cf.taste.impl.model.file.FileDataModel;
import org.apache.mahout.cf.taste.impl.model.jdbc.MySQLJDBCDataModel;

import java.io.File;
import java.io.PrintWriter;
import java.util.List;
import java.util.LinkedList;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.Statement;

import com.mysql.jdbc.jdbc2.optional.MysqlDataSource;
//import com.mysql.jdbc.jdbc2.optional.MysqlConnectionPoolDataSource;

import javax.ws.rs.client.Client;
import javax.ws.rs.client.ClientBuilder;
import javax.ws.rs.core.Response;
import javax.ws.rs.client.WebTarget;

import static test.Utils.*;

public class TestBasic extends TestBase {
	
	private DataModel model;
	private List<RecommendedItem> recommendations;
	
	// From example at,
	//	https://mahout.apache.org/users/recommender/userbased-5-minutes.html
	@Given("^four users and their item preferences$")
	public void four_users_and_their_item_preferences() throws Exception {
		
		File csvFile = new File("TestBasic.csv");
		PrintWriter pw = new PrintWriter(csvFile);
		
		// User 1
		pw.println("1,10,1.0");
		pw.println("1,11,2.0");
		pw.println("1,12,5.0");
		pw.println("1,13,5.0");
		pw.println("1,14,5.0");
		pw.println("1,15,4.0");
		pw.println("1,16,5.0");
		pw.println("1,17,1.0");
		pw.println("1,18,5.0");
		
		// User 2
		pw.println("2,10,1.0");
		pw.println("2,11,2.0");
		pw.println("2,15,5.0");
		pw.println("2,16,4.5");
		pw.println("2,17,1.0");
		pw.println("2,18,5.0");
		
		// User 3
		pw.println("3,11,2.5");
		pw.println("3,12,4.5");
		pw.println("3,13,4.0");
		pw.println("3,14,3.0");
		pw.println("3,15,3.5");
		pw.println("3,16,4.5");
		pw.println("3,17,4.0");
		pw.println("3,18,5.0");
		
		// User 4
		pw.println("4,10,5.0");
		pw.println("4,11,5.0");
		pw.println("4,12,5.0");
		pw.println("4,13,0.0");
		pw.println("4,14,2.0");
		pw.println("4,15,3.0");
		pw.println("4,16,1.0");
		pw.println("4,17,4.0");
		pw.println("4,18,1.0");
		
		pw.close();
		
		this.model = new FileDataModel(csvFile);
	}
	
	@Given("^ten users with identical item preferences$")
	public void ten_users_with_identical_item_preferences() throws Exception {
		
		File csvFile = new File("TestBasic.csv");
		PrintWriter pw = new PrintWriter(csvFile);

		pw.println("1,100,3.5");
		pw.println("1,101,2.8");
		pw.println("1,105,1.1");
		pw.println("1,115,3.4");
		
		pw.println("2,100,3.5");
		pw.println("2,101,2.8");
		pw.println("2,105,1.1");
		pw.println("2,115,3.4");
		
		pw.println("3,100,3.5");
		pw.println("3,101,2.8");
		pw.println("3,105,1.1");
		pw.println("3,115,3.4");
		
		pw.println("4,100,3.5");
		pw.println("4,101,2.8");
		pw.println("4,105,1.1");
		pw.println("4,115,3.4");
		
		pw.println("5,100,3.5");
		pw.println("5,101,2.8");
		pw.println("5,105,1.1");
		pw.println("5,115,3.4");
		
		pw.println("6,100,3.5");
		pw.println("6,101,2.8");
		pw.println("6,105,1.1");
		pw.println("6,115,3.4");
		
		pw.println("7,100,3.5");
		pw.println("7,101,2.8");
		pw.println("7,105,1.1");
		pw.println("7,115,3.4");
		
		pw.println("8,100,3.5");
		pw.println("8,101,2.8");
		pw.println("8,105,1.1");
		pw.println("8,115,3.4");
		
		pw.println("9,100,3.5");
		pw.println("9,101,2.8");
		pw.println("9,105,1.1");
		pw.println("9,115,3.4");
		
		pw.println("10,100,3.5");
		pw.println("10,101,2.8");
		pw.close();
		
		this.model = new FileDataModel(csvFile);
	}
	
	/*
	 * MySql command reference:
	 *	http://www.pantz.org/software/mysql/mysqlcommands.html
	 */
	@Given("^four users and their item preferences in a database$")
	public void four_users_and_their_item_preferences_in_a_database() throws Exception {
		
		MysqlDataSource dataSource = new MysqlDataSource();
		//ConnectionPoolDataSource dataSource = new MysqlConnectionPoolDataSource();
		dataSource.setUser("test");
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
	
	@When("^I locally request two recommendations for a user$")
	public void i_locally_request_two_recommendations_for_a_user() throws Exception {
		double neighborhoodThreshold = 0.1;
		long userId = 10;
		
		/*
		RecommenderBuilder builder = new RecommenderBuilder() {
			public Recommender buildRecommender() {
				UserSimilarity similarity = new PearsonCorrelationSimilarity(dataModel);
				UserNeighborhood neighborhood = new ThresholdUserNeighborhood(0.1, similarity, dataModel);
				return new GenericUserBasedRecommender(dataModel, neighborhood, similarity);
			}
		}
		
		DataModel model = new FileDataModel(this.csvFile);
		RecommenderEvaluator evaluator = new AverageAbsoluteDifferenceRecommenderEvaluator();
		RecommenderBuilder builder = builder;
		double result = evaluator.evaluate(builder, null, model, 0.9, 1.0);
		System.out.println(result);		
		*/
		
		this.recommendations = (new UserSimilarityRecommender(this.model)).recommend(
			neighborhoodThreshold, userId, 2);
		
		System.out.println("Recommended items (" + this.recommendations.size() + "):");
		for (RecommendedItem recommendation : this.recommendations) {
			System.out.println(recommendation.getItemID());
		}
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
	
	static class RecommendationMessage {
		public RecommendationMessage(long itemID, float value) {
			this.itemID = itemID;
			this.value = value;
		}
		
		public long itemID;
		public float value;
		
		public long getItemID() { return this.itemID; }
		public void setItemID(long id) { this.itemID = id; }
		public float getValue() { return this.value; }
		public void setValue(float v) { this.value = v; }
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
	
	@Then("^I obtain two recommendations$")
	public void i_obtain_two_recommendations() throws Exception {
		assertThat(this.recommendations.size() == 2, "Expected items to have 2" +
			" elements, but it has " + this.recommendations.size());
	}
	
	@Then("^I obtain one recommendation$")
	public void i_obtain_one_recommendation() throws Exception {
		assertThat(this.recommendations.size() == 1, "Expected items to have 1" +
			" elements, but it has " + this.recommendations.size());
	}
}
