# This file should not need to be edited, except to update the version number.
# Build configurations are set in an environment file, which is env.mac by default.
# To use a different environment configuration, run this makefile as,
# 	make env=<other-env-file>
# where <other-env-file> is a file that defines the required environment variables,
# just as env.mac does. For example, to use the env.vm environment configuration,
# use this command:
# 	make env=env.vm

ifdef env
	include env
else
	include env.mac
endif

# Names: -----------------------------------------------------------------------

export VERSION := 0.1
export PROJECTROOT := $(shell pwd)
export JAVASRCDIR := $(PROJECTROOT)/java
export unit_test_dir := $(PROJECTROOT)/test-unit
export bdd_test_dir := $(PROJECTROOT)/test-bdd
export PRODUCTNAME := TF-IDF Recommender
export ORG := Scaled Markets
export GROUPNAME := recommender
export PROJECTNAME := tfidf
export main_class := scaledmarkets.recommenders.mahout.UserSimularityRecommender
export CPU_ARCH:=$(shell uname -s | tr '[:upper:]' '[:lower:]')_amd64
export APP_JAR_NAME := $(PROJECTNAME)-$(VERSION).jar
export MESSAGES_JAR_NAME := $(PROJECTNAME)-messages-$(VERSION).jar
export ImageName := scaledmarkets/$(PROJECTNAME)-usersimrec
export unit_test_package := unittest
export bdd_test_package := bddtest

# Locations of generated artifacts: --------------------------------------------

export MAVENBUILDDIR := $(PROJECTROOT)/maven/usersimrec
export IMAGEBUILDDIR := $(PROJECTROOT)/images/usersimrec
export unit_test_build_dir := $(PROJECTROOT)/test-unit/classes
export bdd_test_maven_build_dir := $(PROJECTROOT)/test-bdd/maven
export message_build_dir := $(PROJECTROOT)/shared/classes

# Tools: -----------------------------------------------------------------------
export SHELL := /bin/bash

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

$(MAVENBUILDDIR):
	mkdir -p $(MAVENBUILDDIR)

$(message_build_dir):
	mkdir -p $(message_build_dir)

compile: $(MAVENBUILDDIR) jar_messages
	$(MVN) compile -U -e

compile_messages: $(message_build_dir)
	$(JAVAC) -source 8 -Xmaxerrs $(maxerrs) \
		-d $(message_build_dir) \
		$(JAVASRCDIR)/scaledmarkets/recommenders/messages/Messages.java

compile_unit_tests:
	$(MVN) test-compile

compile_bdd_tests: #$(test_build_dir) compile_messages
	$(MVN) -f pom-bdd.xml -U -e compile

# Create the directory into which the jars will be created.

$(jar_dir):
	mkdir -p $(jar_dir)

# Create the user similarity recommender jar.

jar_app: $(jar_dir) compile
	echo "Main-Class: $(main_class)" > UserSimRecManifest
	echo "Specification-Title: $(PRODUCT_NAME) User Similarity Recommender" >> UserSimRecManifest
	echo "Specification-Version: $(VERSION)" >> UserSimRecManifest
	echo "Specification-Vendor: $(ORG)" >> UserSimRecManifest
	echo "Implementation-Title: $(main_class)" >> UserSimRecManifest
	echo "Implementation-Vendor: $(ORG)" >> UserSimRecManifest
	jar cfm $(jar_dir)/$(APP_JAR_NAME) \
		UserSimRecManifest -C $(MAVENBUILDDIR)/classes scaledmarkets
	rm UserSimRecManifest

# Create jar file for the messages that are sent by the recommender. This is the
# public interface of the application.
jar_messages: $(jar_dir) compile_messages
	echo "Specification-Title: $(PRODUCT_NAME) Message Types" >> UserSimRecMessagesManifest
	echo "Specification-Version: $(VERSION)" >> UserSimRecMessagesManifest
	echo "Specification-Vendor: $(ORG)" >> UserSimRecMessagesManifest
	echo "Implementation-Title: $(main_class)" >> UserSimRecMessagesManifest
	echo "Implementation-Vendor: $(ORG)" >> UserSimRecMessagesManifest
	jar cfm $(jar_dir)/$(MESSAGES_JAR_NAME) \
		UserSimRecMessagesManifest -C $(message_build_dir) scaledmarkets
	rm UserSimRecMessagesManifest
	# Install in the local repository so that the maven compile and the bdd test
	# can find it.
	$(MVN) install:install-file -Dfile=$(jar_dir)/$(MESSAGES_JAR_NAME) -DgroupId=$(GROUPNAME) \
		-DartifactId=$(PROJECTNAME)-messages -Dversion=$(VERSION) -Dpackaging=jar

# Build the user similarity recommender container image.

$(IMAGEBUILDDIR):
	mkdir -p $(IMAGEBUILDDIR)

image: $(IMAGEBUILDDIR) jar
	if [ -z $(DockerhubUserId) ]; then echo "Dockerhub credentials not set"; exit 1; fi
	cp $(jar_dir)/$(APP_JAR_NAME) $(IMAGEBUILDDIR)
	# Copy external jars that the runtime needs.
	# Note: Use 'mvn dependency:build-classpath' to obtain dependencies.
	mkdir -p $(IMAGEBUILDDIR)/jars
	{ \
	cp=`${MVN} dependency:build-classpath | tail -n 8 | head -n 1`; \
	for path in $(echo $classpath | tr ":" "\n"); do cp path $(IMAGEBUILDDIR)/jars; done; \
	}
	# Execute docker build to create an image.
	PROJECTNAME=$(PROJECTNAME) APP_JAR_NAME=$(APP_JAR_NAME) docker build \
		--tag=$(ImageName) $(IMAGEBUILDDIR)
	# Copy the message jar. These are the message types that the recommender sends.
	cp $(jar_dir)/$(MESSAGES_JAR_NAME) $(IMAGEBUILDDIR)/jars
	# Push image to dockerhub.
	sudo docker login -u $(DockerhubUserId) -p $(DockerhubPassword)
	sudo docker push $(ImageName)
	sudo docker logout

# Compile the test source files.

$(test_build_dir):
	mkdir -p $(test_build_dir)

# Run unit tests.
unit_test: #compile_unit_tests jar
	$(MVN) test

# Deploy for running behavioral tests.
# This deploys locally by running main - no container is used.
# Note: The mysql part of this task must be run on a docker host - but OS-X docker
# does not seem to work with the mysql image.
bdd_deploy_local: #start_mysql
	# Run the recognizer directly (as a Java app - not as a container).
	$(JAVA) -cp $(jar_dir)/$(APP_JAR_NAME):`${MVN} dependency:build-classpath | tail -n 8 | head -n 1` \
		scaledmarkets.recommenders.mahout.UserSimilarityRecommender \
		mysql localhost 3306 UserPrefs test test 8080 0.1 verbose

# Deploy for running behavioral tests.
# Note: change this to use a mysql config file, and use a mysql acct other than root.
bdd_deploy: start_mysql
	# Obtain the application image.
	docker login -u $(DockerhubUserId) -p $(DockerhubPassword)
	docker pull $(ImageName)
	docker logout
	# Run the Compose file to deploy the recommender.
	ImageName=$(ImageName) \
		DATABASE_NAME=test \
		MYSQL_HOST=localhost \
		MYSQL_PORT=3306 \
		TABLE_NAME=UserPrefs \
		MYSQL_USER=test \
		MYSQL_PASSWORD=test \
		PORT=8080 \
		NEIGHBORHOOD_THRESHOLD=0.1 \
		docker-compose up -d

# Install the artifacts required for mysql.
prep_mysql:
	# Create volume for the database.
	sudo docker volume create dbcreate
	sudo mkdir -p /var/lib/docker/volumes/dbcreate/_data
	# Copy the database creation SQL to the volume area.
	sudo cp create_schema.sql /var/lib/docker/volumes/dbcreate/_data

start_mysql:
	MYSQL_ROOT_PASSWORD=test \
		MYSQL_DATABASE=mysql \
		MYSQL_USER=test \
		MYSQL_PASSWORD=test \
		docker-compose -f test-bdd/docker-compose-mysql.yml up -d

# Run BDD tests.
bdd: #compile_bdd_tests bdd_deploy
	# Use maven to determine the classpath for the test program, and then run the test program.
	{ \
	cp=`${MVN} -f pom-bdd.xml dependency:build-classpath | tail -n 8 | head -n 1`; \
	$$JAVA -cp $$bdd_test_maven_build_dir/classes:$$jar_dir/$$MESSAGES_JAR_NAME:$$cp \
		cucumber.api.cli.Main \
		--glue $(bdd_test_package) $(bdd_test_dir)/features \
		--tags @done --tags @usersimrec --tags @database; \
	}
	# Stop mysql.
	docker stop mysql
	docker rm mysql

test: unit_test bdd

# Housekeeping.

clean:
	rm -r -f $(MAVENBUILDDIR)/*
	rm -r -f $(IMAGEBUILDDIR)
	docker volume rm dbcreate

info:
	@echo "Makefile for $(PRODUCTNAME)"
