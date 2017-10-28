# What this is
Basic TF-IDF recommender microservice

Notes for running mahout under hadoop:

```
hadoop fs -put u.data u.data  # copy the file u.data to HDFS

hadoop jar <MAHOUT DIRECTORY>/mahout-core-0.7-job.jar \
	org.apache.mahout.cf.taste.hadoop.item.RecommenderJob \
	
	Mahout options:
	
	--similarityClassname SIMILARITY_COOCCURRENCE \
	--input u.data \
	--output output

hadoop fs -getmerge output output.txt
```

To do:

 * Wrap the JDBC model with the ReloadFromJDBCDataModel to load data into memory.
 * Create a version that uses HDFS and hadoop to support a large dataset, to prepare
 	the recommender in the background.
 * Create a version that uses NearestNUserNeighborhood.
 * Create an item-based recommender, using GenericItemSimilarity and GenericItemBasedRecommender.

