package unittest;

import scaledmarkets.recommenders.mahout.UserSimilarityRecommender;

import com.google.gson.Gson;
import com.google.gson.JsonSyntaxException;

import org.apache.mahout.cf.taste.recommender.RecommendedItem;
import org.apache.mahout.cf.taste.model.DataModel;
import org.apache.mahout.cf.taste.impl.model.file.FileDataModel;
import org.apache.mahout.cf.taste.impl.model.jdbc.MySQLJDBCDataModel;
import org.apache.mahout.cf.taste.similarity.UserSimilarity;
import org.apache.mahout.cf.taste.impl.similarity.PearsonCorrelationSimilarity;
import org.apache.mahout.cf.taste.neighborhood.UserNeighborhood;
import org.apache.mahout.cf.taste.impl.neighborhood.ThresholdUserNeighborhood;
import org.apache.mahout.cf.taste.recommender.UserBasedRecommender;
import org.apache.mahout.cf.taste.impl.recommender.GenericUserBasedRecommender;

import java.io.File;
import java.io.PrintWriter;
import java.util.List;
import java.util.LinkedList;

import static unittest.Utils.*;

import org.junit.*;
import static org.junit.Assert.assertEquals;

public class TestBasic extends TestBase {
	
	private DataModel model;
	private List<RecommendedItem> recommendations;
	
	public TestBasic()
	{
	}
	
	@BeforeClass
	public static void setupClass()
	{
		System.out.println("Setting up class");
	}
	
	@AfterClass
	public static void teardownClass()
	{
		System.out.println("Tearing down class");
	}
	
	@Before
	public void setup()
	{
		System.out.println("Setting up");
	}
	
	@After
	public void teardown()
	{
		System.out.println("Tearing down");
	}
	
	// Scenario: Basic functionality
	@Test
	public void testBasic() throws Exception {

		given_four_users_and_their_item_preferences();
		when_i_request_two_recommendations_using_pearson_correlation(4L);
		then_i_obtain_two_recommendations();
	}
	
	// Scenario: All users the same
	@Test
	public void testAllUsersSame() throws Exception {

		given_ten_users_with_identical_item_preferences();
		when_i_request_two_recommendations_using_user_similarity(10L);
		then_i_obtain_two_recommendations();
	}

	// From example at,
	//	https://mahout.apache.org/users/recommender/userbased-5-minutes.html
	protected void given_four_users_and_their_item_preferences() throws Exception {
		
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
	
	protected void given_ten_users_with_identical_item_preferences() throws Exception {
		
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

	protected void when_i_request_two_recommendations_using_pearson_correlation(long userId) throws Exception {
		
		UserSimilarity similarity = new PearsonCorrelationSimilarity(this.model);
		UserNeighborhood neighborhood = new ThresholdUserNeighborhood(0.1, similarity, this.model);
		UserBasedRecommender recommender = new GenericUserBasedRecommender(this.model, neighborhood, similarity);
		this.recommendations = recommender.recommend(2, 2);
	}

	protected void when_i_request_two_recommendations_using_user_similarity(long userId) throws Exception {
		
		double neighborhoodThreshold = 0.1;
		this.recommendations = (new UserSimilarityRecommender(this.model)).recommend(
			neighborhoodThreshold, userId, 2);
	}

	protected void then_i_obtain_two_recommendations() throws Exception {
		assertThat(this.recommendations.size() == 2, "Expected items to have 2" +
			" elements, but it has " + this.recommendations.size());
	}
}
