# This file should not need to be edited, except to update the version number.
# Build configurations are set in an environment file, which is env.mac by default.
# To use a different environment configuration, run this makefile as,
# 	make env=<other-env-file>
# where <other-env-file> is a file that defines the required environment variables,
# just as env.mac does. For example, to use the env.vm environment configuration,
# use this command:
# 	make env=env.vm

ifdef env
	include $(env)
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
export CONSOL_JARS_NAME := $(PROJECTNAME)-consol-jars-$(VERSION).jar
export ImageName := scaledmarkets/$(PROJECTNAME)-tfidf
export unit_test_package := unittest
export bdd_test_package := bddtest

# Locations of generated artifacts: --------------------------------------------

export MAVENBUILDDIR := $(PROJECTROOT)/maven/tfidf
export IMAGEBUILDDIR := $(PROJECTROOT)/images/tfidf
export unit_test_build_dir := $(PROJECTROOT)/test-unit/classes
export bdd_test_maven_build_dir := $(PROJECTROOT)/test-bdd/maven
export message_build_dir := $(PROJECTROOT)/shared/classes

# Tools: -----------------------------------------------------------------------
export SHELL := /bin/bash

# For Maven: -------------------------------------------------------------------
export JAVA_HOME := $(MVN_JAVA_HOME)

# Tasks: -----------------------------------------------------------------------

.DEFAULT_GOAL: all
.PHONY: clean manifest info compile compilepop compilesearch compile pop_jar search_jar jar image
.DELETE_ON_ERROR:
.ONESHELL:
.NOTPARALLEL:
.SUFFIXES:

all: image

$(MAVENBUILDDIR):
	mkdir -p $(MAVENBUILDDIR)

$(scratch_dir)
	mkdir -p $(scratch_dir)

build: $(MAVENBUILDDIR) manifest
	$(MVN) clean install


# Identify all of the dependent Jars that will be needed to deploy.

getdeps:
	$(MVN) dependency:build-classpath --projects service | tail -n $(mvn_spaces) | head -n 1 | tr ":" "\n" > service_jars.txt
	$(MVN) dependency:build-classpath --projects messages | tail -n $(mvn_spaces) | head -n 1 | tr ":" "\n" > messages_jars.txt

showdeps: getdeps
	sort -u service_jars.txt messages_jars.txt

copydeps: $(scratch_dir) getdeps
	cp $(jar_dir)/$(APP_JAR_NAME) $(scratch_dir)
	# Copy external jars that the runtime needs.
	# Note: Use 'mvn dependency:build-classpath' to obtain dependencies.
	{ \
	cp=`sort -u service_jars.txt messages_jars.txt` ; \
	for path in $$cp; do cp $$path $$scratch_dir/jars; done; \
	}

# Create a jar file that contains only the classes that are actually needed to
# run the application. We will omit the Spark Java classes from this calcuation
# because it is unclear which SparkJava classes are the root classes, and so
# our computation would be suspect, and spark core is only 134K.
consolidate:
	java -cp $(JARCON_ROOT):$(CDA_ROOT)/lib/*:$(JOPT_SIMPLE) com.cliffberg.jarcon.JarConsolidator \
		--jarPath="$(jar_dir)/$(APP_JAR_NAME):$(MYSQL_DRIVER):$(scratch_dir)/jars/*" \
		--rootClasses=scaledmarkets.recommenders.mahout.UserSimilarityRecommender,com.mysql.jdbc.log.StandardLogger,com.mysql.jdbc.StandardSocketFactory \
		--properties=com/mysql/jdbc/LocalizedErrorMessages.properties \
		--targetJarPath=$(jar_dir)/$(CONSOL_JARS_NAME) \
		--manifestVersion="1.0.0" --createdBy="Cliff Berg"

# Build the user similarity recommender container image.

$(IMAGEBUILDDIR):
	mkdir -p $(IMAGEBUILDDIR)

copy_to_imagebuilddir: $(IMAGEBUILDDIR)
	cp $(jar_dir)/$(CONSOL_JARS_NAME) $(IMAGEBUILDDIR)
	cp $(jar_dir)/$(APP_JAR_NAME) $(IMAGEBUILDDIR)
	cp Dockerfile $(IMAGEBUILDDIR)
	
image: $(IMAGEBUILDDIR)
	# Check that dockerhub credentials are set.
	if [ -z $(DockerhubUserId) ]; then echo "Dockerhub credentials not set"; exit 1; fi
	# Execute docker build to create an image.
	PROJECTNAME=$(PROJECTNAME) APP_JAR_NAME=$(APP_JAR_NAME) sudo docker build \
		--tag=$(ImageName) $(IMAGEBUILDDIR)
	# Push image to dockerhub.
	sudo docker login -u $(DockerhubUserId) -p $(DockerhubPassword)
	sudo docker push $(ImageName)
	sudo docker logout

# Run unit tests.
unit_test: #compile_unit_tests jar
	$(MVN) test

# Install the artifacts required for mysql.
prep_mysql:
	# Create volume for the database.
	sudo docker volume create dbcreate
	sudo mkdir -p /var/lib/docker/volumes/dbcreate/_data
	# Copy the database creation SQL to the volume area.
	sudo cp create_schema.sql /var/lib/docker/volumes/dbcreate/_data

# To connect from shell,
#	mysql -h localhost -u root -ptest -P 3306 --protocol=TCP
start_mysql:
	MYSQL_ROOT_PASSWORD=test \
		MYSQL_DATABASE=test \
		MYSQL_USER=test \
		MYSQL_PASSWORD=test \
		docker-compose -f test-bdd/docker-compose-mysql.yml up -d

stop_mysql:
	docker stop mysql
	docker rm mysql
	docker volume rm testbdd_dbdata

# Fill the database with test data.
populate_test:
	{ \
	cp=`${MVN} -f pom-bdd.xml dependency:build-classpath | tail -n 8 | head -n 1`; \
	echo cp=$$cp; \
	${JAVA} -cp $$bdd_test_maven_build_dir/classes:$$cp bddtest.PopulateForTest; \
	}

# Deploy for running behavioral tests, using the consol-jars jar.
bdd_deploy_local_consol_jars:
	$(JAVA) -cp $(jar_dir)/$(CONSOL_JARS_NAME):$(SLF4J) \
		scaledmarkets.recommenders.mahout.UserSimilarityRecommender \
		test localhost 3306 UserPrefs test test 8080 0.1 verbose

# Deploy for running behavioral tests.
# This deploys locally by running main - no container is used.
# Note: The mysql part of this task must be run on a docker host - but OS-X docker
# does not seem to work with the mysql image.
bdd_deploy_local: #start_mysql
	# Run the recognizer directly (as a Java app - not as a container).
	$(JAVA) -cp $(jar_dir)/$(APP_JAR_NAME):`${MVN} dependency:build-classpath | tail -n 8 | head -n 1` \
		scaledmarkets.recommenders.mahout.UserSimilarityRecommender \
		test localhost 3306 UserPrefs test test 8080 0.1 verbose

# Deploy for running behavioral tests.
# Note: change this to use a mysql config file, and use a mysql acct other than root.
# https://stackoverflow.com/questions/2121829/com-mysql-jdbc-exceptions-jdbc4-communicationsexceptioncommunications-link-fail#2121962
bdd_deploy: #start_mysql populate_test
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

# Display the dependencies of the behavioral tests.
showdeps_test:
	$(MVN) dependency:build-classpath

# Run BDD tests.
bdd:
	# Use maven to determine the classpath for the test program, and then run the test program.
	{ \
	cp=`${MVN} -f pom-bdd.xml dependency:build-classpath | tail -n 7 | head -n 1`; \
	echo $$cp > bdd_jars.txt; \
	$$JAVA -cp $$bdd_test_maven_build_dir/classes:$$jar_dir/$$MESSAGES_JAR_NAME:$$cp \
		cucumber.api.cli.Main \
		--glue $(bdd_test_package) $(bdd_test_dir)/features \
		--tags @done --tags @tfidf --tags @database; \
	}

test: unit_test bdd

# Housekeeping.

clean:
	rm -r -f $(MAVENBUILDDIR)/*
	rm -r -f $(IMAGEBUILDDIR)
	docker volume rm dbcreate

info:
	@echo "Makefile for $(PRODUCTNAME)"
