package scaledmarkets.recommenders.solr;

// https://github.com/apache/mahout/tree/master/mr/src/main/java/org/apache/mahout/cf/taste/recommender
import org.apache.mahout.cf.taste.recommender.RecommendedItem;

// https://github.com/apache/mahout/tree/master/mr/src/main/java/org/apache/mahout/cf/taste/model
import org.apache.mahout.cf.taste.model.DataModel;

// https://github.com/apache/mahout/tree/master/mr/src/main/java/org/apache/mahout/cf/taste/impl
import org.apache.mahout.cf.taste.impl.model.file.FileDataModel;
import org.apache.mahout.cf.taste.impl.neighborhood.NearestNUserNeighborhood;
import org.apache.mahout.cf.taste.impl.recommender.GenericUserBasedRecommender;
import org.apache.mahout.cf.taste.impl.recommender.CachingRecommender;

// https://github.com/apache/mahout/tree/master/mr/src/main/java/org/apache/mahout/math/hadoop/similarity/cooccurrence/measures
import org.apache.mahout.math.hadoop.similarity.cooccurrence.measures.PearsonCorrelationSimilarity;

// https://github.com/apache/mahout/tree/master/mr/src/main/java/org/apache/mahout/cf/taste/recommender
import org.apache.mahout.cf.taste.recommender.Recommender;


/**
 * Obtain a recommendation for a specified user, based on the user's similarity
 * to other users, in terms of the preferences that the user has expressed for
 * a set of items.
 * 
 * Code comes from examole at,
 *	https://mahout.apache.org/users/recommender/recommender-documentation.html
 */

public class Recommender {
	public static void main(String[] args) throws Exception {

	// Define a data model.
	DataModel model = new FileDataModel(new File("data.txt"));
	
	// Select a user similarity strategy.
	UserSimilarity userSimilarity = new PearsonCorrelationSimilarity(model);
	UserNeighborhood neighborhood =
		new NearestNUserNeighborhood(3, userSimilarity, model);
	
	// Create a recommender.
	Recommender recommender =
		new GenericUserBasedRecommender(model, neighborhood, userSimilarity);
	Recommender cachingRecommender = new CachingRecommender(recommender);
	
	// Obtain recommendations.
	List<RecommendedItem> recommendations =
		cachingRecommender.recommend(1234, 10);
}
