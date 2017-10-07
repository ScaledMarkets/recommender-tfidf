package scaledmarkets.recommenders.mahout;

// https://github.com/apache/mahout/tree/master/mr/src/main/java/org/apache/mahout/cf/taste/recommender
import org.apache.mahout.cf.taste.recommender.RecommendedItem;

// https://github.com/apache/mahout/tree/master/mr/src/main/java/org/apache/mahout/cf/taste/model
import org.apache.mahout.cf.taste.model.DataModel;

// https://github.com/apache/mahout/tree/master/mr/src/main/java/org/apache/mahout/cf/taste/similarity
import org.apache.mahout.cf.taste.similarity.UserSimilarity;

// https://github.com/apache/mahout/tree/master/mr/src/main/java/org/apache/mahout/cf/taste/impl
import org.apache.mahout.cf.taste.impl.model.file.FileDataModel;
import org.apache.mahout.cf.taste.impl.neighborhood.ThresholdUserNeighborhood;
//import org.apache.mahout.cf.taste.impl.neighborhood.NearestNUserNeighborhood;
import org.apache.mahout.cf.taste.impl.recommender.GenericUserBasedRecommender;
import org.apache.mahout.cf.taste.impl.recommender.CachingRecommender;

// https://github.com/apache/mahout/tree/branch-0.13.0/mr/src/main/java/org/apache/mahout/cf/taste/neighborhood
import org.apache.mahout.cf.taste.neighborhood.UserNeighborhood;

// https://github.com/apache/mahout/blob/branch-0.13.0/mr/src/main/java/org/apache/mahout/cf/taste/impl/similarity/PearsonCorrelationSimilarity.java
import org.apache.mahout.cf.taste.impl.similarity.PearsonCorrelationSimilarity;

// https://github.com/apache/mahout/tree/master/mr/src/main/java/org/apache/mahout/cf/taste/recommender
import org.apache.mahout.cf.taste.recommender.Recommender;

// https://github.com/apache/mahout/blob/master/mr/src/main/java/org/apache/mahout/cf/taste/model/JDBCDataModel.java
import org.apache.mahout.cf.taste.model.JDBCDataModel;

// https://github.com/apache/mahout/blob/08e02602e947ff945b9bd73ab5f0b45863df3e53/integration/src/main/java/org/apache/mahout/cf/taste/impl/model/jdbc/MySQLJDBCDataModel.java
import org.apache.mahout.cf.taste.impl.model.jdbc.MySQLJDBCDataModel;

import java.io.File;
import java.util.List;
import javax.sql.DataSource;

import static spark.Spark.*;
import com.google.gson.Gson;

/**
 * Obtain a recommendation for a specified user, based on the user's similarity
 * to other users, in terms of the preferences that the user has expressed for
 * a set of items.
 * 
 * Code comes from example at,
 *	https://mahout.apache.org/users/recommender/recommender-documentation.html
 *
 * See also,
 *	https://mahout.apache.org/users/recommender/userbased-5-minutes.html
 *
 * To use Apache Spark:
 *	https://mahout.apache.org/users/environment/how-to-build-an-app.html
 */
public class UserSimilarityRecommender {
		
	final static int NeighborhoodSize = 1;
	final static double NeighborhoodThreshold = 0.1;
	
	public static void main(String[] args) throws Exception {

		if ((args.length >= 1) &&
				(args[0].equals("-h") || args[0].equals("help") ||
					args[0].equals("--help") || args[0].equals("-help"))) {
			printUsage();
			System.exit(1);
		}
		
		if (args.length != 2) {
			printUsage();
			System.exit(1);
		}
		
		// Parse the arguments.
		String databaseURL = args[0];
		String databaseTableName = args[1];
		
		Context context = new InitialContext();
		DataSource dataSource = context.lookup("java:comp/env/" + ....dataSourceName);
		context.close();
		
		// Define a data model.
		// Connect to database.
		// To use HDFS:
		// https://mahout.apache.org/users/classification/bayesian.html
		// https://chimpler.wordpress.com/2013/02/20/playing-with-the-mahout-recommendation-engine-on-a-hadoop-cluster/
		JDBCDataModel model = new MySQLJDBCDataModel(DataSource dataSource,
			String preferenceTable,
			String userIDColumn,
			String itemIDColumn,
			String preferenceColumn,
			String timestampColumn);
		
		// Create a singleton instance of our recommender.
		UserSimilarityRecommender recommender = new UserSimilarityRecommender(model);
		
		// Install REST handler that invokes our recommender.
		// For info on SparkJava Web service framework (not related to Apache Spark):
		//	http://blog.sahil.me/posts/simple-web-services-and-java/
		//	http://sparkjava.com/
		get("/recommend", "application/json", (Request request, Response response) -> {
			
			String thresholdStr = request.queryParams("threshold");
			String userIdStr = request.queryParams("userid");
			
			double threshold = Double.parseDouble(thresholdStr);
			long userId = Long.parseLong(userIdStr);

			RecommendedItem rec;
			List<RecommendedItem> recs = 
				recommender.recommend(threshold, userId, 1);
			
			if (recs.size() == 0) {
				rec = null;
			} else if (recs.size() == 1) {
				rec = recs.get(0);
			} else throw new RuntimeException(
				"Multiple recommendations returned");
				
			// Construct output message.
			if (rec == null) {
				return new NoRecommendationMessage();
			} else {
				return new RecommendationMessage(rec.getItemID(), rec.getValue());
			}
			
		}, new JsonTransformer());  // render message as JSON
	}
	
	private DataModel model;
	
	protected UserSimilarityRecommender(DataModel model) {
		this.model = model;
	}
	
	public List<RecommendedItem> recommend(double neighborhoodThreshold, long userId, int noOfRecs) throws Exception {
		
		// Select a user similarity strategy.
		UserSimilarity userSimilarity = new PearsonCorrelationSimilarity(this.model);
		UserNeighborhood neighborhood =
			new ThresholdUserNeighborhood(
				neighborhoodThreshold, userSimilarity, model);
		
		// Create a recommender.
		Recommender recommender =
			new GenericUserBasedRecommender(model, neighborhood, userSimilarity);
		//Recommender cachingRecommender = new CachingRecommender(recommender);
		
		// Obtain recommendations.
		List<RecommendedItem> recommendations =
			recommender.recommend(userId, noOfRecs);
		
		return recommendations;
	}
	
	static class JsonTransformer implements ResponseTransformer {
		private Gson gson = new Gson();
		
		@Override
		public String render(Object model) {
			return gson.toJson(model);
		}
	}
	
	static class NoRecommendationMessage {
		public String message = "No recommendations";
		public String getMessage() { return this.message; }
		public void setMessage(String message) { this.message = message; }
	}
	
	static class RecommendationMessage {
		RecommendationMessage() {
			
		}
		
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
	
	public static class JsonTransformer implements ResponseTransformer {
	
		private Gson gson = new Gson();
	
		@Override
		public String render(Object model) {
			return gson.toJson(model);
		}
	
	}
	
	static void printUsage() {
		System.out.println("requires arguments:");
		System.out.println("\tdatabase-URL");
		System.out.println("\tdatabase-table-name");
	}
}
