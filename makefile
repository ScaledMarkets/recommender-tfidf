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
	# Before doing that, make sure JAVA_HOME is set as in makefile.inc.
	mkdir -p $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/com/sparkjava/spark-core/2.5/spark-core-2.5.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/slf4j/slf4j-api/1.7.13/slf4j-api-1.7.13.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/eclipse/jetty/jetty-server/9.3.6.v20151106/jetty-server-9.3.6.v20151106.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/javax/servlet/javax.servlet-api/3.1.0/javax.servlet-api-3.1.0.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/eclipse/jetty/jetty-http/9.3.6.v20151106/jetty-http-9.3.6.v20151106.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/eclipse/jetty/jetty-util/9.3.6.v20151106/jetty-util-9.3.6.v20151106.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/eclipse/jetty/jetty-io/9.3.6.v20151106/jetty-io-9.3.6.v20151106.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/eclipse/jetty/jetty-webapp/9.3.6.v20151106/jetty-webapp-9.3.6.v20151106.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/eclipse/jetty/jetty-xml/9.3.6.v20151106/jetty-xml-9.3.6.v20151106.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/eclipse/jetty/jetty-servlet/9.3.6.v20151106/jetty-servlet-9.3.6.v20151106.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/eclipse/jetty/jetty-security/9.3.6.v20151106/jetty-security-9.3.6.v20151106.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/eclipse/jetty/websocket/websocket-server/9.3.6.v20151106/websocket-server-9.3.6.v20151106.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/eclipse/jetty/websocket/websocket-common/9.3.6.v20151106/websocket-common-9.3.6.v20151106.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/eclipse/jetty/websocket/websocket-client/9.3.6.v20151106/websocket-client-9.3.6.v20151106.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/eclipse/jetty/websocket/websocket-servlet/9.3.6.v20151106/websocket-servlet-9.3.6.v20151106.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/eclipse/jetty/websocket/websocket-api/9.3.6.v20151106/websocket-api-9.3.6.v20151106.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/mysql/mysql-connector-java/8.0.8-dmr/mysql-connector-java-8.0.8-dmr.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/com/google/code/gson/gson/2.8.2/gson-2.8.2.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/mahout/mahout-math/0.13.0/mahout-math-0.13.0.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/commons/commons-math3/3.2/commons-math3-3.2.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/com/google/guava/guava/14.0.1/guava-14.0.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/it/unimi/dsi/fastutil/7.0.12/fastutil-7.0.12.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/com/tdunning/t-digest/3.1/t-digest-3.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/mahout/mahout-core/0.9/mahout-core-0.9.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/codehaus/jackson/jackson-core-asl/1.9.12/jackson-core-asl-1.9.12.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/codehaus/jackson/jackson-mapper-asl/1.9.12/jackson-mapper-asl-1.9.12.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/commons/commons-lang3/3.1/commons-lang3-3.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/com/thoughtworks/xstream/xstream/1.4.4/xstream-1.4.4.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/xmlpull/xmlpull/1.1.3.1/xmlpull-1.1.3.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/xpp3/xpp3_min/1.1.4c/xpp3_min-1.1.4c.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/lucene/lucene-core/4.6.1/lucene-core-4.6.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/lucene/lucene-analyzers-common/4.6.1/lucene-analyzers-common-4.6.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/mahout/commons/commons-cli/2.0-mahout/commons-cli-2.0-mahout.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/solr/solr-commons-csv/3.5.0/solr-commons-csv-3.5.0.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/hadoop/hadoop-core/1.2.1/hadoop-core-1.2.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/commons-cli/commons-cli/1.2/commons-cli-1.2.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/com/sun/jersey/jersey-core/1.8/jersey-core-1.8.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/com/sun/jersey/jersey-json/1.8/jersey-json-1.8.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/codehaus/jettison/jettison/1.1/jettison-1.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/stax/stax-api/1.0.1/stax-api-1.0.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/com/sun/xml/bind/jaxb-impl/2.2.3-1/jaxb-impl-2.2.3-1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/javax/xml/bind/jaxb-api/2.2.2/jaxb-api-2.2.2.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/javax/xml/stream/stax-api/1.0-2/stax-api-1.0-2.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/javax/activation/activation/1.1/activation-1.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/codehaus/jackson/jackson-jaxrs/1.7.1/jackson-jaxrs-1.7.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/codehaus/jackson/jackson-xc/1.7.1/jackson-xc-1.7.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/com/sun/jersey/jersey-server/1.8/jersey-server-1.8.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/asm/asm/3.1/asm-3.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/commons-httpclient/commons-httpclient/3.0.1/commons-httpclient-3.0.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/commons-codec/commons-codec/1.4/commons-codec-1.4.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/commons/commons-math/2.1/commons-math-2.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/commons-configuration/commons-configuration/1.6/commons-configuration-1.6.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/commons-collections/commons-collections/3.2.1/commons-collections-3.2.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/commons-digester/commons-digester/1.8/commons-digester-1.8.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/commons-beanutils/commons-beanutils/1.7.0/commons-beanutils-1.7.0.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/commons-beanutils/commons-beanutils-core/1.8.0/commons-beanutils-core-1.8.0.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/commons-net/commons-net/1.4.1/commons-net-1.4.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/commons-el/commons-el/1.0/commons-el-1.0.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/mahout/mahout-integration/0.13.0/mahout-integration-0.13.0.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/mahout/mahout-hdfs/0.13.0/mahout-hdfs-0.13.0.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/hadoop/hadoop-client/2.4.1/hadoop-client-2.4.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/hadoop/hadoop-hdfs/2.4.1/hadoop-hdfs-2.4.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/log4j/log4j/1.2.17/log4j-1.2.17.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/hadoop/hadoop-mapreduce-client-app/2.4.1/hadoop-mapreduce-client-app-2.4.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/hadoop/hadoop-mapreduce-client-common/2.4.1/hadoop-mapreduce-client-common-2.4.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/hadoop/hadoop-yarn-client/2.4.1/hadoop-yarn-client-2.4.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/com/sun/jersey/jersey-client/1.9/jersey-client-1.9.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/hadoop/hadoop-yarn-server-common/2.4.1/hadoop-yarn-server-common-2.4.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/hadoop/hadoop-mapreduce-client-shuffle/2.4.1/hadoop-mapreduce-client-shuffle-2.4.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/slf4j/slf4j-log4j12/1.7.5/slf4j-log4j12-1.7.5.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/hadoop/hadoop-yarn-api/2.4.1/hadoop-yarn-api-2.4.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/hadoop/hadoop-mapreduce-client-jobclient/2.4.1/hadoop-mapreduce-client-jobclient-2.4.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/hadoop/hadoop-annotations/2.4.1/hadoop-annotations-2.4.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/com/fasterxml/jackson/core/jackson-core/2.7.4/jackson-core-2.7.4.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/mahout/mahout-mr/0.13.0/mahout-mr-0.13.0.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/commons-io/commons-io/2.4/commons-io-2.4.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/hbase/hbase-client/1.0.0/hbase-client-1.0.0.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/hbase/hbase-annotations/1.0.0/hbase-annotations-1.0.0.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/hbase/hbase-common/1.0.0/hbase-common-1.0.0.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/mortbay/jetty/jetty-util/6.1.26/jetty-util-6.1.26.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/hbase/hbase-protocol/1.0.0/hbase-protocol-1.0.0.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/commons-lang/commons-lang/2.6/commons-lang-2.6.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/commons-logging/commons-logging/1.2/commons-logging-1.2.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/com/google/protobuf/protobuf-java/2.5.0/protobuf-java-2.5.0.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/io/netty/netty-all/4.0.23.Final/netty-all-4.0.23.Final.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/zookeeper/zookeeper/3.4.6/zookeeper-3.4.6.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/htrace/htrace-core/3.1.0-incubating/htrace-core-3.1.0-incubating.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/jruby/jcodings/jcodings/1.0.8/jcodings-1.0.8.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/jruby/joni/joni/2.1.2/joni-2.1.2.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/hadoop/hadoop-auth/2.5.1/hadoop-auth-2.5.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/httpcomponents/httpclient/4.2.5/httpclient-4.2.5.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/httpcomponents/httpcore/4.2.4/httpcore-4.2.4.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/directory/server/apacheds-kerberos-codec/2.0.0-M15/apacheds-kerberos-codec-2.0.0-M15.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/directory/server/apacheds-i18n/2.0.0-M15/apacheds-i18n-2.0.0-M15.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/directory/api/api-asn1-api/1.0.0-M20/api-asn1-api-1.0.0-M20.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/directory/api/api-util/1.0.0-M20/api-util-1.0.0-M20.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/hadoop/hadoop-common/2.5.1/hadoop-common-2.5.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/xmlenc/xmlenc/0.52/xmlenc-0.52.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/avro/avro/1.7.4/avro-1.7.4.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/com/thoughtworks/paranamer/paranamer/2.3/paranamer-2.3.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/xerial/snappy/snappy-java/1.0.4.1/snappy-java-1.0.4.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/com/jcraft/jsch/0.1.42/jsch-0.1.42.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/com/google/code/findbugs/jsr305/1.3.9/jsr305-1.3.9.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/commons/commons-compress/1.4.1/commons-compress-1.4.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/tukaani/xz/1.0/xz-1.0.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/hadoop/hadoop-mapreduce-client-core/2.5.1/hadoop-mapreduce-client-core-2.5.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/apache/hadoop/hadoop-yarn-common/2.5.1/hadoop-yarn-common-2.5.1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/io/netty/netty/3.6.2.Final/netty-3.6.2.Final.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/com/github/stephenc/findbugs/findbugs-annotations/1.3.9-1/findbugs-annotations-1.3.9-1.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/junit/junit/4.11/junit-4.11.jar $(USERSIMRECIMAGEBUILDDIR)/jars
	cp $(MavenRepo)/org/hamcrest/hamcrest-core/1.3/hamcrest-core-1.3.jar $(USERSIMRECIMAGEBUILDDIR)/jars
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
