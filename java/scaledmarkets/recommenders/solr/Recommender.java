package scaledmarkets.recommenders.solr;

import org.apache.mahout.cf.taste.model.DataModel;
import org.apache.mahout.cf.taste.impl.model.file.FileDataModel;
import org.apache.mahout.math.hadoop.similarity.cooccurrence.measures.PearsonCorrelationSimilarity;
import org.apache.mahout.cf.taste.impl.neighborhood.NearestNUserNeighborhood;
import org.apache.mahout.cf.taste.impl.recommender.GenericUserBasedRecommender;
import org.apache.mahout.cf.taste.impl.recommender.CachingRecommender;
import org.apache.mahout.cf.taste.recommender.RecommendedItem;


// https://mahout.apache.org/users/recommender/recommender-documentation.html

public class Recommender {
	public static void main(String[] args) throws Exception {


	DataModel model = new FileDataModel(new File("data.txt"));
	UserSimilarity userSimilarity = new PearsonCorrelationSimilarity(model);
	UserNeighborhood neighborhood =
		new NearestNUserNeighborhood(3, userSimilarity, model);{code}
	Recommender recommender =
		new GenericUserBasedRecommender(model, neighborhood, userSimilarity);
	Recommender cachingRecommender = new CachingRecommender(recommender);
	List<RecommendedItem> recommendations =
		cachingRecommender.recommend(1234, 10);


}
