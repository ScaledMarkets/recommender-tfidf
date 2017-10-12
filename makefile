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
export POPJAVABUILDDIR := $(PROJECTROOT)/classes/pop
export SEARCHJAVABUILDDIR := $(PROJECTROOT)/classes/search
export USERSIMRECJAVABUILDDIR := $(PROJECTROOT)/classes/usersimrec
export POPIMAGEBUILDDIR := $(PROJECTROOT)/images/pop
export SEARCHIMAGEBUILDDIR := $(PROJECTROOT)/images/search
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

$(POPJAVABUILDDIR):
	mkdir -p $(POPJAVABUILDDIR)

compilepop: $(POPJAVABUILDDIR)
	javac -Xmaxerrs $(maxerrs) -cp $(SOLR_CP) -d $(POPJAVABUILDDIR) \
		$(JAVASRCDIR)/scaledmarkets/recommenders/solr/SolrjPopulator.java

$(SEARCHJAVABUILDDIR):
	mkdir -p $(SEARCHJAVABUILDDIR)

compilesearch: $(SEARCHJAVABUILDDIR)
	javac -Xmaxerrs $(maxerrs) -cp $(SOLR_CP) -d $(SEARCHJAVABUILDDIR) \
		$(JAVASRCDIR)/scaledmarkets/recommenders/solr/SolrJSearcher.java

$(USERSIMRECJAVABUILDDIR):
	mkdir -p $(USERSIMRECJAVABUILDDIR)

compileusersimrec: $(USERSIMRECJAVABUILDDIR)
	javac -Xmaxerrs $(maxerrs) \
		-cp $(MAHOUT_CP):$(MYSQL_JDBC_CP):$(SPARK_CP):$(GSON_CP) \
		-d $(USERSIMRECJAVABUILDDIR) \
		$(JAVASRCDIR)/scaledmarkets/recommenders/mahout/UserSimilarityRecommender.java

# Create the directory into which the jars will be created.

$(jar_dir):
	mkdir -p $(jar_dir)

# Create the Populator jar.

pop_jar: $(jar_dir)/$(POP_JAR_NAME)

$(jar_dir)/$(POP_JAR_NAME): compilepop $(jar_dir)
	echo "Main-Class: $(pop_main_class)" > PopManifest
	echo "Specification-Title: $(PRODUCT_NAME) Populator" >> PopManifest
	echo "Specification-Version: $(VERSION)" >> PopManifest
	echo "Specification-Vendor: $(ORG)" >> PopManifest
	echo "Implementation-Title: $(pop_main_class)" >> PopManifest
	echo "Implementation-Vendor: $(ORG)" >> PopManifest
	jar cfm $(jar_dir)/$(POP_JAR_NAME) PopManifest \
		-C $(POPJAVABUILDDIR) scaledmarkets
	rm PopManifest

# Create the Search jar.

search_jar: $(jar_dir)/$(SEARCH_JAR_NAME)

$(jar_dir)/$(SEARCH_JAR_NAME): compilesearch $(jar_dir)
	echo "Main-Class: $(search_main_class)" > SearchManifest
	echo "Specification-Title: $(PRODUCT_NAME) Searcher" >> SearchManifest
	echo "Specification-Version: $(VERSION)" >> SearchManifest
	echo "Specification-Vendor: $(ORG)" >> SearchManifest
	echo "Implementation-Title: $(search_main_class)" >> SearchManifest
	echo "Implementation-Vendor: $(ORG)" >> SearchManifest
	jar cfm $(jar_dir)/$(SEARCH_JAR_NAME) SearchManifest \
		-C $(SEARCHJAVABUILDDIR) scaledmarkets
	rm SearchManifest

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

# Build the Populator container image.

$(POPIMAGEBUILDDIR):
	mkdir -p $(POPIMAGEBUILDDIR)

popimage: $(POPIMAGEBUILDDIR) pop_jar
	if [ -z $(DockerhubUserId) ]; then echo "Dockerhub credentials not set"; exit 1; fi
	cp $(jar_dir)/$(POP_JAR_NAME) $(POPIMAGEBUILDDIR)
	PROJECTNAME=$(PROJECTNAME) POP_JAR_NAME=$(POP_JAR_NAME) docker build \
		--tag=$(PopImageName) $(POPIMAGEBUILDDIR)
	docker login -u $(DockerhubUserId) -p $(DockerhubPassword)
	docker push $(PopImageName)
	docker logout

# Build the Search container image.

$(SEARCHIMAGEBUILDDIR):
	mkdir -p $(SEARCHIMAGEBUILDDIR)

searchimage: $(SEARCHIMAGEBUILDDIR) search_jar
	if [ -z $(DockerhubUserId) ]; then echo "Dockerhub credentials not set"; exit 1; fi
	cp $(jar_dir)/$(SEARCH_JAR_NAME) $(SEARCHIMAGEBUILDDIR)
	PROJECTNAME=$(PROJECTNAME) SEARCH_JAR_NAME=$(SEARCH_JAR_NAME) docker build \
		--tag=$(SearchImageName) $(SEARCHIMAGEBUILDDIR)
	docker login -u $(DockerhubUserId) -p $(DockerhubPassword)
	docker push $(SearchImageName)
	docker logout

# Build the user similarity recommender container image.

$(USERSIMRECIMAGEBUILDDIR):
	mkdir -p $(USERSIMRECIMAGEBUILDDIR)

usersimrecimage: $(USERSIMRECIMAGEBUILDDIR) usersimrec_jar
	if [ -z $(DockerhubUserId) ]; then echo "Dockerhub credentials not set"; exit 1; fi
	cp $(jar_dir)/$(USERSIMREC_JAR_NAME) $(USERSIMRECIMAGEBUILDDIR)
	# Copy other jars that the runtime needs:
	mkdir -p $(USERSIMRECIMAGEBUILDDIR)/jars/solr
	mkdir -p $(USERSIMRECIMAGEBUILDDIR)/jars/solr/solrj-lib
	mkdir -p $(USERSIMRECIMAGEBUILDDIR)/jars/mahout
	mkdir -p $(USERSIMRECIMAGEBUILDDIR)/jars/mahout/lib
	mkdir -p $(USERSIMRECIMAGEBUILDDIR)/jars/mysql
	mkdir -p $(USERSIMRECIMAGEBUILDDIR)/jars/sparkjava
	mkdir -p $(USERSIMRECIMAGEBUILDDIR)/jars/gson
	cp $(SOLR_HOME)/dist/*.jar $(USERSIMRECIMAGEBUILDDIR)/jars/solr
	cp $(SOLR_HOME)/dist/solrj-lib/*.jar $(USERSIMRECIMAGEBUILDDIR)/jars/solr/solrj-lib
	cp $(MAHOUT_HOME)/*.jar $(USERSIMRECIMAGEBUILDDIR)/jars/mahout
	cp $(MAHOUT_HOME)/lib/*.jar $(USERSIMRECIMAGEBUILDDIR)/jars/mahout/lib
	cp $(MYSQL_JDBC_HOME)/*.jar $(USERSIMRECIMAGEBUILDDIR)/jars/mysql
	cp $(SparkJavaHome)/*.jar $(USERSIMRECIMAGEBUILDDIR)/jars/sparkjava
	cp $(GSON_HOME)/*.jar $(USERSIMRECIMAGEBUILDDIR)/jars/gson
	PROJECTNAME=$(PROJECTNAME) USERSIMREC_JAR_NAME=$(USERSIMREC_JAR_NAME) docker build \
		--tag=$(UserSimRecImageName) $(USERSIMRECIMAGEBUILDDIR)
	docker login -u $(DockerhubUserId) -p $(DockerhubPassword)
	docker push $(UserSimRecImageName)
	docker logout

# Compile the test source files.

$(test_build_dir):
	mkdir -p $(test_build_dir)

compile_tests: $(test_build_dir)
	javac -Xmaxerrs $(maxerrs) \
		-cp $(jar_dir)/$(USERSIMREC_JAR_NAME):$(CUCUMBER_CP):$(MAHOUT_CP):$(test_build_dir) \
		-d $(test_build_dir) \
		$(test_dir)/steps/$(test_package)/*.java

# Run unit tests.

unit_usersimrec: compile_tests usersimrec_jar
	# Run unit tests.
	java -cp $(CUCUMBER_CP):$(test_build_dir) \
		cucumber.api.cli.Main \
		--glue $(test_package) $(test_dir)/features \
		--tags @done --tags @usersimrec --tags @file

# Deploy the current for test.
# Note: change this to use a mysql config file, and use a mysql acct other than root.
deploy: 
	sudo docker volume create dbcreate
	sudo mkdir -p /var/lib/docker/volumes/dbcreate/_data
	sudo cp create_schema.sql /var/lib/docker/volumes/dbcreate/_data
	UserSimRecImageName=$(UserSimRecImageName) \
		MYSQL_ROOT_PASSWORD=test \
		MYSQL_USER=test MYSQL_PASSWORD=test \
		docker-compose up

# Run acceptance tests.
accept_usersimrec: compile_tests deploy
	java -cp $(CUCUMBER_CP):$(test_build_dir):$(GSON_CP) \
		cucumber.api.cli.Main \
		--glue $(test_package) $(test_dir)/features \
		--tags @done --tags @usersimrec --tags @database

test: unit_usersimrec accept_usersimrec

# Housekeeping.

clean:
	rm -r -f $(POPJAVABUILDDIR)/*
	rm -r -f $(POPIMAGEBUILDDIR)/*
	rm -r -f $(SEARCHJAVABUILDDIR)/*
	rm -r -f $(SEARCHIMAGEBUILDDIR)
	rm -r -f $(USERSIMRECJAVABUILDDIR)/*
	rm -r -f $(USERSIMRECIMAGEBUILDDIR)
	docker volume rm dbcreate

info:
	@echo "Makefile for $(PRODUCTNAME)"
