FROM docker.io/centos:7

# Create directories:
RUN mkdir /recommender-usersim
RUN mkdir /jars
RUN mkdir /jars/solr
RUN mkdir /jars/solr/dist
RUN mkdir /jars/mahout
RUN mkdir /jars/mahout/lib
RUN mkdir /jars/mysql
RUN mkdir /jars/sparkjava
RUN mkdir /jars/gson

# Add the recommender:
ADD ["recommender-usersim.jar", "/recommender-usersim/"]

# Add jars needed by recommender:
ADD ["jars/solr/dist/*.jar", "/jars/solr"]
ADD ["jars/solr/dist/solrj-lib/*.jar", "/jars/solr/dist"]
ADD ["jars/mahout/*.jar", "/jars/mahout"]
ADD ["jars/mahout/lib/*.jar", "/jars/mahout/lib"]
ADD ["jars/mysql/*.jar", "/jars/mysql"]
ADD ["jars/sparkjava/*.jar", "/jars/sparkjava"]
ADD ["jars/gson/*.jar", "/jars/gson"]

# Set working directory:
WORKDIR /recommender-usersim/

# Run the command that starts the recommender service:
#CMD ["java", "-cp", "/recommender-usersim/*:/jars/solr/*:/jars/solr/solrj-lib/*:/jars/mahout/*:/jars/mahout/lib/*:/jars/mysql/*:/jars/sparkjava/*:/jars/gson/*", "scaledmarkets.recommenders.mahout.UserSimilarityRecommender"]
