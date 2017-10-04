package scaledmarkets.recommenders.solr;

// https://github.com/apache/mahout/tree/master/mr/src/main/java/org/apache/mahout/cf/taste/recommender
import org.apache.mahout.cf.taste.recommender.RecommendedItem;

// https://github.com/apache/mahout/tree/master/mr/src/main/java/org/apache/mahout/cf/taste/model
import org.apache.mahout.cf.taste.model.DataModel;

// https://github.com/apache/mahout/tree/master/mr/src/main/java/org/apache/mahout/cf/taste/similarity
import org.apache.mahout.cf.taste.similarity.UserSimilarity;

// https://github.com/apache/mahout/tree/master/mr/src/main/java/org/apache/mahout/cf/taste/impl
import org.apache.mahout.cf.taste.impl.model.file.FileDataModel;
import org.apache.mahout.cf.taste.impl.neighborhood.NearestNUserNeighborhood;
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
 * To use Spark:
 *	https://mahout.apache.org/users/environment/how-to-build-an-app.html
 */

public class UserSimilarityRecommender {
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
		
		// Obtain the user Id from the arguments.
		String filePath = args[0];
		long userId = Long.parseLong(args[1]);
		
		final int NoOfRecommendations = 10;
		final int NeighborhoodSize = 3;
		
		// Define a data model.
		DataModel model = new FileDataModel(new File(filePath));
		
		// Select a user similarity strategy.
		UserSimilarity userSimilarity = new PearsonCorrelationSimilarity(model);
		UserNeighborhood neighborhood =
			new NearestNUserNeighborhood(
				NeighborhoodSize, userSimilarity, model);
		
		// Create a recommender.
		Recommender recommender =
			new GenericUserBasedRecommender(model, neighborhood, userSimilarity);
		Recommender cachingRecommender = new CachingRecommender(recommender);
		
		// Obtain recommendations.
		List<RecommendedItem> recommendations =
			cachingRecommender.recommend(userId, NoOfRecommendations);
		
		for (RecommendedItem recommendation : recommendations) {
			System.out.println(recommendation);
		}
	}
	
	public static void printUsage() {
		System.out.println("requires arguments:");
		System.out.println("\tfile-path - location of csv file, containing lines\n" +
			"\t\tof the form \"userID,itemID,prefValue\" (e.g. \"39505,290002,3.5\")");
		System.out.println("\tuserID - the user for which to provide recommendations");
	}
}
