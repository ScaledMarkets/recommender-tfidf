FROM docker.io/centos:7
....switch to alpine

# Install Java:
RUN yum install -y java-1.8.0-openjdk
....switch to 9

# https://docs.oracle.com/javase/9/tools/javapackager.htm
# http://openjdk.java.net/jeps/275
# http://openjdk.java.net/projects/jigsaw/quick-start
....use javapackager (jlink)


# Create directories:
RUN mkdir /recommender-usersim
RUN mkdir /jars
RUN mkdir /jars/mahout
RUN mkdir /jars/mysql
RUN mkdir /jars/sparkjava
RUN mkdir /jars/gson

# Add the recommender:
ADD ["recommender_tfidf-usersimrec.jar", "/recommender-usersim/"]

# Add jars needed by recommender:
ADD ["jars/mysql/*.jar", "/jars/mysql/"]
ADD ["jars/sparkjava/*.jar", "/jars/sparkjava/"]
ADD ["jars/gson/*.jar", "/jars/gson/"]
ADD ["jars/mahout/*.jar", "/jars/mahout/"]

# Set working directory:
WORKDIR /recommender-usersim/

# Run the command that starts the recommender service.
# Command arguments are provided by the docker-compose file 'command'.
ENTRYPOINT ["/usr/bin/java", "-cp", "/recommender-usersim/*:/jars/*", "scaledmarkets.recommenders.mahout.UserSimilarityRecommender"]
