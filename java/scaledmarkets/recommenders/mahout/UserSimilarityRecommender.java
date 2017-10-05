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

import java.io.File;
import java.util.List;

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
 *
 * For info on SparkJava Web service framework (not related to Apache Spark):
 *	http://blog.sahil.me/posts/simple-web-services-and-java/
 *	http://sparkjava.com/
 */
public class UserSimilarityRecommender {
	
	private Gson gson = new Gson();
	
	final static int NeighborhoodSize = 1;
	final static double NeighborhoodThreshold = 0.1;
	
	@Override
	public String render(Object model) {
		return gson.toJson(model);
	}	
	
	public static void main(String[] args) throws Exception {

		get("/recommend", "application/json", (Request request, Response response) -> {
			
			String thresholdStr = request.queryParams("threshold");
			String userIdStr = request.queryParams("userid");
			String numOfRecsStr = request.queryParams("numberofrecs");
			
			....replace FileDataModel with a database
			
			// https://mahout.apache.org/users/classification/bayesian.html
			// https://chimpler.wordpress.com/2013/02/20/playing-with-the-mahout-recommendation-engine-on-a-hadoop-cluster/
			
		}, new JsonTransformer());
		
			

		
		
		
		/*
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
		
		// Obtain the user Id from the arguments.
		String filePath = args[0];
		long userId = Long.parseLong(args[1]);
		
		final int NoOfRecommendations = 10;
		
		UserSimilarityRecommender rec = new UserSimilarityRecommender();
		List<RecommendedItem> recommendations = rec.recommend(
			new File(filePath), NeighborhoodThreshold, userId, NoOfRecommendations);
//			new File(filePath), NeighborhoodSize, userId, NoOfRecommendations);
		
		for (RecommendedItem recommendation : recommendations) {
			System.out.println(recommendation.getItemID());
		}
		*/
	}
	
	public List<RecommendedItem> recommend(File csvFile, double neighborhoodThreshold, long userId, int noOfRecs) throws Exception {
		
		// Define a data model.
		DataModel model = new FileDataModel(csvFile);
		
		// Select a user similarity strategy.
		UserSimilarity userSimilarity = new PearsonCorrelationSimilarity(model);
		UserNeighborhood neighborhood =
			new ThresholdUserNeighborhood(
				neighborhoodThreshold, userSimilarity, model);
//			new NearestNUserNeighborhood(
//				neighborhoodSize, userSimilarity, model);
		
		// Create a recommender.
		Recommender recommender =
			new GenericUserBasedRecommender(model, neighborhood, userSimilarity);
		//Recommender cachingRecommender = new CachingRecommender(recommender);
		
		// Obtain recommendations.
		List<RecommendedItem> recommendations =
			recommender.recommend(userId, noOfRecs);
		
		return recommendations;
	}
	
	/*
	public static void printUsage() {
		System.out.println("requires arguments:");
		System.out.println("\tfile-path - location of csv file, containing lines\n" +
			"\t\tof the form \"userID,itemID,prefValue\" (e.g. \"39505,290002,3.5\")");
		System.out.println("\tuserID - the user for which to provide recommendations");
	}
	*/
}
