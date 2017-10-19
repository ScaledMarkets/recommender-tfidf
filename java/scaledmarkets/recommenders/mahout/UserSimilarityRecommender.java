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
import com.mysql.cj.jdbc.MysqlDataSource;

import static spark.Spark.get;
import static spark.Spark.port;
import spark.ResponseTransformer;
import spark.Request;
import spark.Response;
import com.google.gson.Gson;

import scaledmarkets.recommenders.messages.Messages.NoRecommendationMessage;
import scaledmarkets.recommenders.messages.Messages.RecommendationMessage;
import scaledmarkets.recommenders.messages.Messages.ErrorMessage;

/**
 * Obtain a recommendation for a specified user, based on the user's similarity
 * to other users, in terms of the preferences that the user has expressed for
 * a set of items. User preference history must be provided in a MySQL table
 * that has columns 'UserID', 'ItemID', and 'Preference'.
 * This implementation is intended for small datasets. For large datasets, use
 * the Hadoop based implemenation, UserSimilarityRecommenderJob, which uses HDFS.
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
		
	static boolean verbose = false;
	
	public static void main(String[] args) throws Exception {

		if ((args.length >= 1) &&
				(args[0].equals("-h") || args[0].equals("help") ||
					args[0].equals("--help") || args[0].equals("-help"))) {
			printUsage();
			System.exit(1);
		}
		
		if (args.length < 7) {
			printUsage();
			System.exit(1);
		}
		
		// Parse the arguments.
		String dbName = args[0];
		String dbHostname = args[1];
		String dbPortStr = args[2];
		String databaseTableName = args[3];
		String dbUsername = args[4];
		String dbPassword = args[5];
		String svcPortStr = args[6];
		if (args.length > 7) {
			if (args[7].equals("verbose")) {
				verbose = true;
			}
		}
		
		int dbPort = Integer.parseInt(dbPortStr);
		int svcPort = Integer.parseInt(svcPortStr);
		
		MysqlDataSource dataSource = new MysqlDataSource();
		//ConnectionPoolDataSource dataSource = new MysqlConnectionPoolDataSource();
		dataSource.setUser(dbUsername);
		dataSource.setPassword(dbPassword);
		dataSource.setServerName(dbHostname);
		dataSource.setPort(dbPort);
		dataSource.setDatabaseName(dbName);
		
		// Define a data model.
		// Connect to database.
		// To use HDFS:
		// https://mahout.apache.org/users/classification/bayesian.html
		// https://chimpler.wordpress.com/2013/02/20/playing-with-the-mahout-recommendation-engine-on-a-hadoop-cluster/
		JDBCDataModel model = new MySQLJDBCDataModel(dataSource,
			databaseTableName,
			"UserID",
			"ItemID",
			"Preference",
			null);
		
		// Create a singleton instance of our recommender.
		UserSimilarityRecommender recommender = new UserSimilarityRecommender(model);
		
		// Install REST handler that invokes our recommender.
		// For info on SparkJava Web service framework (not related to Apache Spark):
		//	http://blog.sahil.me/posts/simple-web-services-and-java/
		//	http://sparkjava.com/
		port(svcPort);
		get("/recommend", "application/json", (Request request, Response response) -> {
			
			if (verbose) System.out.println("Received request...");
			
			try {
				String userIdStr = request.queryParams("userid");
				String thresholdStr = request.queryParams("threshold");
				
				if (userIdStr.equals("")) {
					response.status(400);
					return new ErrorMessage("Missing query parm: userid");
				}
				
				if (thresholdStr.equals("")) {
					response.status(400);
					return new ErrorMessage("Missing query parm: threshold");
				}
				
				if (verbose) System.out.println("Received parameters: userid=" + userIdStr +
					", threshold=" + thresholdStr);
				
				double threshold = Double.parseDouble(thresholdStr);
				long userId = Long.parseLong(userIdStr);
	
				List<RecommendedItem> recs = recommender.recommend(threshold, userId, 1);
				
				if (verbose) System.out.println("Obtained recommendation...");
				
				RecommendedItem rec;
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
			} catch (Throwable t) {
				response.status(500);
				return new ErrorMessage(t.getMessage());
			} finally {
				if (verbose) System.out.println("...returning.");
			}
			
		}, new JsonTransformer());  // render message as JSON
	}
	
	private DataModel model;
	
	public UserSimilarityRecommender(DataModel model) {
		this.model = model;
	}
	
	/**
	 * Use Mahout to analyze the data and generate a recommendation.
	 */
	public List<RecommendedItem> recommend(double neighborhoodThreshold, long userId, int noOfRecs) throws Exception {
		
		// Select a user similarity strategy.
		if (verbose) System.out.println("Defining a PearsonCorrelationSimilarity...");
		UserSimilarity userSimilarity = new PearsonCorrelationSimilarity(this.model);
		UserNeighborhood neighborhood =
			new ThresholdUserNeighborhood(
				neighborhoodThreshold, userSimilarity, model);
				
		// Create a recommender.
		if (verbose) System.out.println("Defining a GenericUserBasedRecommender...");
		Recommender recommender =
			new GenericUserBasedRecommender(model, neighborhood, userSimilarity);
		//Recommender cachingRecommender = new CachingRecommender(recommender);
				
		// Obtain recommendations.
		if (verbose) System.out.println("Calling recommend on the recommender...");
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
	
	static void printUsage() {
		System.out.println("requires arguments:");
		System.out.println("\tdatabase-name");
		System.out.println("\tdatabase-host");
		System.out.println("\tdatabase-port");
		System.out.println("\tdatabase-table-name - table must contain columns\n" +
			"\t\t'UserID', 'ItemID', and 'Preference'.");
		System.out.println("\tdatabase-username");
		System.out.println("\tdatabase-password");
		System.out.println("\tport on which the recommender service should run");
		System.out.println("\tverbose (optional) - the string 'verbose'");
	}
}
