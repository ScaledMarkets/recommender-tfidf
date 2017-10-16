# This file should not need to be edited. Build configurations are set in
# makefile.inc.

include makefile.inc

# Names: -----------------------------------------------------------------------

export PRODUCTNAME := TF-IDF Recommender
export ORG := Scaled Markets
export VERSION := 0.1
export PROJECTNAME := recommender_tfidf
export pop_main_class := scaledmarkets.recommenders.solr.SolrjPopulator
export search_main_class := scaledmarkets.recommenders.solr.SolrjSearcher
export usersimrec_main_class := scaledmarkets.recommenders.mahout.UserSimularityRecommender
export CPU_ARCH:=$(shell uname -s | tr '[:upper:]' '[:lower:]')_amd64
export POP_JAR_NAME := $(PROJECTNAME)-pop.jar
export SEARCH_JAR_NAME := $(PROJECTNAME)-search.jar
export USERSIMREC_JAR_NAME := $(PROJECTNAME)-usersimrec.jar
export PopImageName := scaledmarkets/$(PROJECTNAME)-pop
export SearchImageName := scaledmarkets/$(PROJECTNAME)-search
export UserSimRecImageName := scaledmarkets/$(PROJECTNAME)-usersimrec
export test_package := test
export MVN := $(MAVEN_HOME)/bin/mvn
export MavenRepo=$(HOME)/.m2/repository
export JAVA := $(JAVA_HOME)/bin/java
export JAVAC := $(JAVA_HOME)/bin/javac

# References: ------------------------------------------------------------------

# http://www.solrtutorial.com/solrj-tutorial.html
# https://lucene.apache.org/solr/6_6_0/solr-core/index.html
# https://lucene.apache.org/solr/guide/6_6/index.html
# For SOLR schema, to customize ranking, see,
#	https://lucene.apache.org/solr/guide/7_0/other-schema-elements.html#similarity
# For finding similar documents, use "More Like This":
#	https://lucene.apache.org/solr/guide/6_6/morelikethis.html

# Locations of generated artifacts: --------------------------------------------

export PROJECTROOT := $(shell pwd)
export JAVASRCDIR := $(PROJECTROOT)/java
export USERSIMRECJAVABUILDDIR := $(PROJECTROOT)/classes/usersimrec
export USERSIMRECIMAGEBUILDDIR := $(PROJECTROOT)/images/usersimrec
export test_dir := $(PROJECTROOT)/test
export test_build_dir := $(PROJECTROOT)/test/classes

# Tools: -----------------------------------------------------------------------
SHELL := /bin/sh

# Tasks: -----------------------------------------------------------------------

.DEFAULT_GOAL: all
.PHONY: clean info compile compilepop compilesearch compileusersimrec pop_jar search_jar usersimrec_jar popimage searchimage usersimrecimage
.DELETE_ON_ERROR:
.ONESHELL:
.NOTPARALLEL:
.SUFFIXES:
.PHONY: compile build clean info
.DELETE_ON_ERROR:

all: popimage searchimage usersimrecimage

# Compile Java files.

compile: compilepop compilesearch compileusersimrec

$(USERSIMRECJAVABUILDDIR):
	mkdir -p $(USERSIMRECJAVABUILDDIR)

compileusersimrec: $(USERSIMRECJAVABUILDDIR)
	$(MVN) compile -U -e

# Create the directory into which the jars will be created.

$(jar_dir):
	mkdir -p $(jar_dir)

# Create the user similarity recommender jar.

usersimrec_jar: $(jar_dir)/$(USERSIMREC_JAR_NAME)

$(jar_dir)/$(USERSIMREC_JAR_NAME): compileusersimrec $(jar_dir)
	echo "Main-Class: $(usersimrec_main_class)" > UserSimRecManifest
	echo "Specification-Title: $(PRODUCT_NAME) Searcher" >> UserSimRecManifest
	echo "Specification-Version: $(VERSION)" >> UserSimRecManifest
	echo "Specification-Vendor: $(ORG)" >> UserSimRecManifest
	echo "Implementation-Title: $(usersimrec_main_class)" >> UserSimRecManifest
	echo "Implementation-Vendor: $(ORG)" >> UserSimRecManifest
	jar cfm $(jar_dir)/$(USERSIMREC_JAR_NAME) UserSimRecManifest \
		-C $(USERSIMRECJAVABUILDDIR) scaledmarkets
	rm UserSimRecManifest

# Build the user similarity recommender container image.

$(USERSIMRECIMAGEBUILDDIR):
	mkdir -p $(USERSIMRECIMAGEBUILDDIR)

usersimrecimage: $(USERSIMRECIMAGEBUILDDIR) usersimrec_jar
	if [ -z $(DockerhubUserId) ]; then echo "Dockerhub credentials not set"; exit 1; fi
	cp $(jar_dir)/$(USERSIMREC_JAR_NAME) $(USERSIMRECIMAGEBUILDDIR)
	# Copy other jars that the runtime needs.
	# Note: Use 'mvn dependency:build-classpath' to obtain dependencies.
	mkdir -p $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/com/sparkjava/spark-core/2.5/spark-core-2.5.jar /jars
	cp $(MavenRepo)/org/slf4j/slf4j-api/1.7.13/slf4j-api-1.7.13.jar /jars
	cp $(MavenRepo)/org/eclipse/jetty/jetty-server/9.3.6.v20151106/jetty-server-9.3.6.v20151106.jar /jars
	cp $(MavenRepo)/javax/servlet/javax.servlet-api/3.1.0/javax.servlet-api-3.1.0.jar /jars
	cp $(MavenRepo)/org/eclipse/jetty/jetty-http/9.3.6.v20151106/jetty-http-9.3.6.v20151106.jar /jars
	cp $(MavenRepo)/org/eclipse/jetty/jetty-util/9.3.6.v20151106/jetty-util-9.3.6.v20151106.jar /jars
	cp $(MavenRepo)/org/eclipse/jetty/jetty-io/9.3.6.v20151106/jetty-io-9.3.6.v20151106.jar /jars
	cp $(MavenRepo)/org/eclipse/jetty/jetty-webapp/9.3.6.v20151106/jetty-webapp-9.3.6.v20151106.jar /jars
	cp $(MavenRepo)/org/eclipse/jetty/jetty-xml/9.3.6.v20151106/jetty-xml-9.3.6.v20151106.jar /jars
	cp $(MavenRepo)/org/eclipse/jetty/jetty-servlet/9.3.6.v20151106/jetty-servlet-9.3.6.v20151106.jar /jars
	cp $(MavenRepo)/org/eclipse/jetty/jetty-security/9.3.6.v20151106/jetty-security-9.3.6.v20151106.jar /jars
	cp $(MavenRepo)/org/eclipse/jetty/websocket/websocket-server/9.3.6.v20151106/websocket-server-9.3.6.v20151106.jar /jars
	cp $(MavenRepo)/org/eclipse/jetty/websocket/websocket-common/9.3.6.v20151106/websocket-common-9.3.6.v20151106.jar /jars
	cp $(MavenRepo)/org/eclipse/jetty/websocket/websocket-client/9.3.6.v20151106/websocket-client-9.3.6.v20151106.jar /jars
	cp $(MavenRepo)/org/eclipse/jetty/websocket/websocket-servlet/9.3.6.v20151106/websocket-servlet-9.3.6.v20151106.jar /jars
	cp $(MavenRepo)/org/eclipse/jetty/websocket/websocket-api/9.3.6.v20151106/websocket-api-9.3.6.v20151106.jar /jars
	cp $(MavenRepo)/mysql/mysql-connector-java/8.0.8-dmr/mysql-connector-java-8.0.8-dmr.jar /jars
	cp $(MavenRepo)/com/google/code/gson/gson/2.8.2/gson-2.8.2.jar /jars
	cp $(MavenRepo)/org/apache/mahout/mahout-math/0.13.0/mahout-math-0.13.0.jar /jars
	cp $(MavenRepo)/org/apache/commons/commons-math3/3.2/commons-math3-3.2.jar /jars
	cp $(MavenRepo)/com/google/guava/guava/14.0.1/guava-14.0.1.jar /jars
	cp $(MavenRepo)/it/unimi/dsi/fastutil/7.0.12/fastutil-7.0.12.jar /jars
	cp $(MavenRepo)/com/tdunning/t-digest/3.1/t-digest-3.1.jar /jars
	PROJECTNAME=$(PROJECTNAME) USERSIMREC_JAR_NAME=$(USERSIMREC_JAR_NAME) docker build \
		--tag=$(UserSimRecImageName) $(USERSIMRECIMAGEBUILDDIR)
	sudo docker login -u $(DockerhubUserId) -p $(DockerhubPassword)
	sudo docker push $(UserSimRecImageName)
	sudo docker logout

# Compile the test source files.

$(test_build_dir):
	mkdir -p $(test_build_dir)

compile_tests: $(test_build_dir)
	$(JAVAC) -source 8 -release 8 -Xmaxerrs $(maxerrs) \
		-cp $(jar_dir)/$(USERSIMREC_JAR_NAME):$(CUCUMBER_CP):$(JAVAXWS_CP):$(GSON_CP):$(MYSQL_JDBC_CP):$(MAHOUT_CP):$(test_build_dir) \
		-d $(test_build_dir) \
		$(test_dir)/steps/$(test_package)/*.java \
		$(JAVASRCDIR)/scaledmarkets/recommenders/messages/Messages.java

# Run unit tests.

unit_usersimrec: compile_tests usersimrec_jar
	# Run unit tests.
	java -cp $(CUCUMBER_CP):$(test_build_dir) \
		cucumber.api.cli.Main \
		--glue $(test_package) $(test_dir)/features \
		--tags @done --tags @usersimrec --tags @file

# Deploy for test.
# This deploys locally by running main - no container is used.
deploy_test:
	java -cp \
		"$(jar_dir)/$(USERSIMREC_JAR_NAME):$(MYSQL_JDBC_HOME)/*:$(SparkJavaHome)/*:$(GSON_HOME)/*:$(MAHOUT_HOME)/*" \
		scaledmarkets.recommenders.mahout.UserSimilarityRecommender \
		mysql localhost 3306 UserPrefs test test

# Deploy.
# Note: change this to use a mysql config file, and use a mysql acct other than root.
deploy: 
	sudo docker volume create dbcreate
	sudo mkdir -p /var/lib/docker/volumes/dbcreate/_data
	sudo cp create_schema.sql /var/lib/docker/volumes/dbcreate/_data
	docker login -u $(DockerhubUserId) -p $(DockerhubPassword)
	docker pull $(UserSimRecImageName)
	docker logout
	UserSimRecImageName=$(UserSimRecImageName) \
		MYSQL_ROOT_PASSWORD=test \
		MYSQL_USER=test MYSQL_PASSWORD=test \
		docker-compose up

# Run acceptance tests.
accept_usersimrec: compile_tests deploy
	java -cp $(CUCUMBER_CP):$(test_build_dir):$(GSON_CP):$(JERSEY_CP) \
		cucumber.api.cli.Main \
		--glue $(test_package) $(test_dir)/features \
		--tags @done --tags @usersimrec --tags @database

test: unit_usersimrec accept_usersimrec

# Housekeeping.

clean:
	rm -r -f $(USERSIMRECJAVABUILDDIR)/*
	rm -r -f $(USERSIMRECIMAGEBUILDDIR)
	docker volume rm dbcreate

info:
	@echo "Makefile for $(PRODUCTNAME)"
