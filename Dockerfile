#FROM docker.io/centos:7
FROM jolokia/alpine-jre-8

# Install Java:
#RUN yum install -y java-1.8.0-openjdk

# Create directories:
RUN mkdir /recommender-tfidf
RUN mkdir /jars

# Add the recommender:
ADD ["${APP_JAR_NAME}", "/recommender-tfidf/"]

# Add jars needed by recommender:
ADD ["jars/*.jar", "/jars/"]

# Set working directory:
WORKDIR /recommender-tfidf/

# Run the command that starts the recommender service.
# Command arguments are provided by the docker-compose file 'command'.
ENTRYPOINT ["java", "-cp", "/recommender-tfidf/*:/jars/*", "com.scaledmarkets.recommenders.mahout.UserSimilarityRecommender"]
