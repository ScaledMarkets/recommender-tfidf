package test;

import scaledmarkets.recommenders.mahout.*;
import org.apache.mahout.cf.taste.recommender.RecommendedItem;

import cucumber.api.Format;
import cucumber.api.java.Before;
import cucumber.api.java.After;
import cucumber.api.java.en.Given;
import cucumber.api.java.en.Then;
import cucumber.api.java.en.When;

import java.io.File;
import java.io.PrintWriter;
import java.util.List;

import static test.Utils.*;

public class TestBasic extends TestBase {
	
	private File csvFile;
	private List<RecommendedItem> items;
	
	@Given("^ten users and their item preferences$")
	public void ten_users_and_their_item_preferences() throws Exception {
		this.csvFile = new File("TestBasic.csv");
		PrintWriter pw = new PrintWriter(this.csvFile);
		pw.println("1,100,3.5");
		pw.println("1,101,2.8");
		pw.println("1,105,1.1");
		pw.println("1,115,3.4");
		pw.println("2,108,2.0");
		pw.println("2,105,4.8");
		pw.println("2,108,.91");
		pw.println("2,109,1.4");
		pw.println("3,115,1.1");
		pw.println("3,108,3.7");
		pw.println("3,113,.34");
		pw.println("3,114,.66");
		pw.println("4,115,4.1");
		pw.println("4,106,1.4");
		pw.println("4,108,.78");
		pw.println("4,112,2.3");
		pw.println("5,113,6.2");
		pw.println("5,101,1.4");
		pw.println("5,104,.99");
		pw.println("5,109,3.8");
		pw.println("6,114,4.2");
		pw.println("6,101,2.4");
		pw.println("6,102,1.8");
		pw.println("6,111,1.3");
		pw.println("7,112,2.9");
		pw.println("7,108,2.4");
		pw.println("7,111,1.3");
		pw.println("7,113,4.1");
		pw.println("8,115,3.9");
		pw.println("8,102,3.2");
		pw.println("8,105,1.6");
		pw.println("8,107,4.1");
		pw.println("9,111,.88");
		pw.println("9,112,3.3");
		pw.println("9,113,2.5");
		pw.println("9,115,6.0");
		pw.println("10,104,3.7");
		pw.println("10,106,2.0");
		pw.println("10,111,1.8");
		pw.println("10,113,3.0");
		pw.close();
	}
	
	@When("^I request two recommendations for a user$")
	public void i_request_two_recommendations_for_a_user() throws Exception {
		long userId = 5;
		this.items = (new UserSimilarityRecommender()).recommend(this.csvFile, userId, 2);
	}
	
	@Then("^I obtain two recommendations$")
	public void i_obtain_two_recommendations() throws Exception {
		assertThat(this.items.size() == 2, "Expected items to have 2" +
			" elements, but it has " + this.items.size());
	}
}
