# This file should not need to be edited. Build configurations are set in
# makefile.inc.

include makefile.inc

# Names: -----------------------------------------------------------------------

export PROJECTROOT := $(shell pwd)
export JAVASRCDIR := $(PROJECTROOT)/java
export unit_test_dir := $(PROJECTROOT)/test-unit
export bdd_test_dir := $(PROJECTROOT)/test-bdd
export PRODUCTNAME := TF-IDF Recommender
export ORG := Scaled Markets
export VERSION := 0.1
export PROJECTNAME := recommender_tfidf
export main_class := scaledmarkets.recommenders.mahout.UserSimularityRecommender
export CPU_ARCH:=$(shell uname -s | tr '[:upper:]' '[:lower:]')_amd64
export POP_JAR_NAME := $(PROJECTNAME)-pop.jar
export SEARCH_JAR_NAME := $(PROJECTNAME)-search.jar
export USERSIMREC_JAR_NAME := $(PROJECTNAME)-usersimrec.jar
export PopImageName := scaledmarkets/$(PROJECTNAME)-pop
export SearchImageName := scaledmarkets/$(PROJECTNAME)-search
export UserSimRecImageName := scaledmarkets/$(PROJECTNAME)-usersimrec
export unit_test_package := unittest
export bdd_test_package := bddtest
export MVN := $(MAVEN_HOME)/bin/mvn

# Locations of generated artifacts: --------------------------------------------

export JAVABUILDDIR := $(PROJECTROOT)/classes/usersimrec
export IMAGEBUILDDIR := $(PROJECTROOT)/images/usersimrec
export unit_test_build_dir := $(PROJECTROOT)/test-unit/classes
export bdd_test_build_dir := $(PROJECTROOT)/test-bdd/classes
export message_build_dir := $(PROJECTROOT)/shared/classes

# Tools: -----------------------------------------------------------------------
export SHELL := /bin/sh
export JAVA := $(JAVA_HOME)/bin/java
export JAVAC := $(JAVA_HOME)/bin/javac

# Tasks: -----------------------------------------------------------------------

.DEFAULT_GOAL: all
.PHONY: clean info compile compilepop compilesearch compile pop_jar search_jar jar image
.DELETE_ON_ERROR:
.ONESHELL:
.NOTPARALLEL:
.SUFFIXES:
.PHONY: compile build clean info
.DELETE_ON_ERROR:

all: image

# Compile Java files.

$(JAVABUILDDIR):
	mkdir -p $(JAVABUILDDIR)

$(message_build_dir):
	mkdir -p $(message_build_dir)

compile: $(JAVABUILDDIR) compile_messages
	$(MVN) compile -U -e

compile_messages: $(message_build_dir)
	$(JAVAC) -source 8 -Xmaxerrs $(maxerrs) \
		-d $(message_build_dir) \
		$(JAVASRCDIR)/scaledmarkets/recommenders/messages/Messages.java

compile_unit_tests:
	$(MVN) test-compile

# Create the directory into which the jars will be created.

$(jar_dir):
	mkdir -p $(jar_dir)

# Create the user similarity recommender jar.

jar: $(jar_dir)/$(USERSIMREC_JAR_NAME)

$(jar_dir)/$(USERSIMREC_JAR_NAME): $(jar_dir)
	echo "Main-Class: $(main_class)" > UserSimRecManifest
	echo "Specification-Title: $(PRODUCT_NAME) Searcher" >> UserSimRecManifest
	echo "Specification-Version: $(VERSION)" >> UserSimRecManifest
	echo "Specification-Vendor: $(ORG)" >> UserSimRecManifest
	echo "Implementation-Title: $(main_class)" >> UserSimRecManifest
	echo "Implementation-Vendor: $(ORG)" >> UserSimRecManifest
	jar cfm $(jar_dir)/$(USERSIMREC_JAR_NAME) UserSimRecManifest \
		-C $(JAVABUILDDIR) scaledmarkets
	rm UserSimRecManifest

# Build the user similarity recommender container image.

$(IMAGEBUILDDIR):
	mkdir -p $(IMAGEBUILDDIR)

image: $(IMAGEBUILDDIR) jar
	if [ -z $(DockerhubUserId) ]; then echo "Dockerhub credentials not set"; exit 1; fi
	cp $(jar_dir)/$(USERSIMREC_JAR_NAME) $(IMAGEBUILDDIR)
	# Copy other jars that the runtime needs.
	# Note: Use 'mvn dependency:build-classpath' to obtain dependencies.
	# Before doing that, make sure JAVA_HOME is set as in makefile.inc.
	mkdir -p $(IMAGEBUILDDIR)/jars
	cp=`mvn dependency:build-classpath | tail -n 8 | head -n 1`
	for p in $(echo $cp | tr ":" "\n"); do cp p $(IMAGEBUILDDIR)/jars; done
	PROJECTNAME=$(PROJECTNAME) USERSIMREC_JAR_NAME=$(USERSIMREC_JAR_NAME) docker build \
		--tag=$(UserSimRecImageName) $(IMAGEBUILDDIR)
	sudo docker login -u $(DockerhubUserId) -p $(DockerhubPassword)
	sudo docker push $(UserSimRecImageName)
	sudo docker logout

# Compile the test source files.

$(test_build_dir):
	mkdir -p $(test_build_dir)

compile_bdd_tests: $(test_build_dir) compile_messages
	$(MVN) -f pom-bdd.xml compile -U -e
	$(JAVAC) -source 8 -Xmaxerrs $(maxerrs) \
		-cp $(jar_dir)/$(USERSIMREC_JAR_NAME):$(CUCUMBER_CP):$(JAVAXWS_CP):$(GSON_CP):$(MYSQL_JDBC_CP):$(MAHOUT_CP):$(test_build_dir) \
		-d $(test_build_dir) \
		$(bdd_test_dir)/steps/$(bdd_test_package)/*.java \
		$(JAVASRCDIR)/scaledmarkets/recommenders/messages/Messages.java

# Run unit tests.
unit_test: compile_unit_tests jar
	$(MVN) test

# Deploy for running behavioral tests.
# This deploys locally by running main - no container is used.
bdd_deploy_local:
	$(JAVA) -cp \
		"$(jar_dir)/$(USERSIMREC_JAR_NAME):$(MYSQL_JDBC_HOME)/*:$(SparkJavaHome)/*:$(GSON_HOME)/*:$(MAHOUT_HOME)/*" \
		scaledmarkets.recommenders.mahout.UserSimilarityRecommender \
		mysql localhost 3306 UserPrefs test test

# Deploy for running behavioral tests.
# Note: change this to use a mysql config file, and use a mysql acct other than root.
bdd_deploy: 
	# Create volume for the database.
	sudo docker volume create dbcreate
	sudo mkdir -p /var/lib/docker/volumes/dbcreate/_data
	# Copy the database creation SQL to the volume area.
	sudo cp create_schema.sql /var/lib/docker/volumes/dbcreate/_data
	# Obtain the application image.
	docker login -u $(DockerhubUserId) -p $(DockerhubPassword)
	docker pull $(UserSimRecImageName)
	docker logout
	# Run the Compose file to deploy.
	UserSimRecImageName=$(UserSimRecImageName) \
		MYSQL_ROOT_PASSWORD=test \
		MYSQL_USER=test MYSQL_PASSWORD=test \
		docker-compose up

# Run BDD tests.
bdd: compile_bdd_tests deploy
	$(JAVA) -cp $(CUCUMBER_CP):$(test_build_dir):$(GSON_CP):$(JERSEY_CP) \
		cucumber.api.cli.Main \
		--glue $(bdd_test_package) $(bdd_test_dir)/features \
		--tags @done --tags @usersimrec --tags @database

test: unit_test bdd

# Housekeeping.

clean:
	rm -r -f $(JAVABUILDDIR)/*
	rm -r -f $(IMAGEBUILDDIR)
	docker volume rm dbcreate

info:
	@echo "Makefile for $(PRODUCTNAME)"
