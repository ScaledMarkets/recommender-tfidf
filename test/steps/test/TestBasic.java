package test;

import scaledmarkets.recommenders.mahout.*;

import cucumber.api.Format;
import cucumber.api.java.Before;
import cucumber.api.java.After;
import cucumber.api.java.en.Given;
import cucumber.api.java.en.Then;
import cucumber.api.java.en.When;

import com.google.gson.Gson;

import org.apache.mahout.cf.taste.recommender.RecommendedItem;

import java.io.File;
import java.io.PrintWriter;
import java.util.List;

import javax.sql.DataSource;
import java.sql.Connection;

import com.mysql.jdbc.jdbc2.optional.MysqlDataSource;
//import com.mysql.jdbc.jdbc2.optional.MysqlConnectionPoolDataSource;



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
		
		DataSource dataSource = new MysqlDataSource();
		//ConnectionPoolDataSource dataSource = new MysqlConnectionPoolDataSource();
		dataSource.setUser(dbUsername);
		dataSource.setPassword(dbPassword);
		dataSource.setServerName(dbHostname);
		dataSource.setPort(dbPort);
		dataSource.setDatabaseName(dbName);

		// Clear database and populate it.
		Connection con = null;
		Statement stmt = null;
		ResultSet null;
		try {
			con = ds.getConnection();
			stmt = con.createStatement();
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
		} catch (SQLException ex) {
			e.printStackTrace();
		} finally {
			try {
				if(rs != null) rs.close();
				if(stmt != null) stmt.close();
				if(con != null) con.close();
			} catch (SQLException e) {
				e.printStackTrace();
			}
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
	
	@When("^I remotely request two recommendations for a user$")
	public void i_remotely_request_two_recommendations_for_a_user() throws Exception {
		
		....Make remote GET request, and verify the JSON response
		
	}
	
	@Then("^I obtain two recommendations$")
	public void i_obtain_two_recommendations() throws Exception {
		assertThat(this.recommendations.size() == 2, "Expected items to have 2" +
			" elements, but it has " + this.recommendations.size());
	}
}
