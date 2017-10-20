# What this is
Basic TF-IDF recommender

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
