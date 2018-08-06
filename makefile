# This file should not need to be edited, except to update the version number.
# Build configurations are set in an environment file, env.mac or env.linux.

export os := $(shell uname)

ifeq ($(os),Darwin)
	include env.mac
endif

ifeq ($(os),Linux)
	include env.linux
endif


# Names: -----------------------------------------------------------------------

export VERSION := 0.1
export ImageName := scaledmarkets/tfidf
export ORG := Scaled Markets
export PROJECTROOT := $(shell pwd)
export PRODUCTNAME := TF-IDF Recommender
export main_class := com.scaledmarkets.recommenders.mahout.UserSimularityRecommender
export SERVICE_JAR_NAME := service-$(VERSION).jar
export MESSAGES_JAR_NAME := messages-$(VERSION).jar
export CONSOL_JARS_NAME := tfidf-consol-jars-$(VERSION).jar
export unit_test_package := unittest
export bdd_test_package := bddtest

# Derived Names: ---------------------------------------------------------------

export MavenProjectPath := $(MavenRepository)/com/scaledmarkets/recommender-tfidf

# Tools: -----------------------------------------------------------------------
export SHELL := /bin/bash

# For Maven: -------------------------------------------------------------------
export JAVA_HOME := $(MVN_JAVA_HOME)

# Tasks: -----------------------------------------------------------------------

.DEFAULT_GOAL: all
.PHONY: regimage consolimage build getdeps showdeps copydeps unit_test_consol_jar consolidate copy_consol_jar_to_imagebuilddir copy_all_jars_to_imagebuilddir image getdeps_unittest showdeps_unittest unit_test prep_mysql start_mysql stop_mysql populate_test bdd_deploy_local_consol_jars bdd_deploy_local bdd_deploy getdeps_bddtest showdeps_bddtest bdd test clean info
.DELETE_ON_ERROR:
.ONESHELL:
.NOTPARALLEL:
.SUFFIXES:

# To build an image, choose one of these. These do not run tests.
regimage: build copydeps copy_all_jars_to_imagebuilddir image
consolimage: build copydeps consolidate copy_consol_jar_to_imagebuilddir image

# Compile all Java source code.
build:
	$(MVN) clean install

getdeps_unittest:
	${MVN} dependency:build-classpath --projects test-unit | tail -n $(mvn_spaces) | head -n 1 > unit_jars.txt

# Display the dependencies of the behavioral tests.
showdeps_unittest: getdeps_unittest
	cat unit_jars.txt

# Run unit tests.
unit_test: #getdeps_unittest
	# Use maven to determine the classpath for the test program, and then run the test program.
	@echo $(MavenProjectPath)/test-unit/$(VERSION)/test-unit-$(VERSION).jar
	{ \
	export cp=`cat unit_jars.txt`; \
	$$JAVA -cp $$MavenProjectPath/test-unit/$$VERSION/test-unit-$$VERSION.jar:$$cp unittest.TestBasic ; \
	}

# Identify all of the dependent Jars that will be needed to deploy.
getdeps:
	$(MVN) dependency:build-classpath --projects service | tail -n $(mvn_spaces) | head -n 1 | tr ":" "\n" > service_jars.txt
	$(MVN) dependency:build-classpath --projects messages | tail -n $(mvn_spaces) | head -n 1 | tr ":" "\n" > messages_jars.txt

# Print dependent Jars.
showdeps: getdeps
	sort -u service_jars.txt messages_jars.txt

# Copy the jars needed by the remote service.
copydeps: getdeps
	rm -r -f $(all_jars_dir)
	mkdir -p $(all_jars_dir)
	cp $(MavenProjectPath)/service/$(VERSION)/service-$(VERSION).jar $(all_jars_dir)
	cp $(MavenProjectPath)/messages/$(VERSION)/messages-$(VERSION).jar $(all_jars_dir)
	# Copy external jars that the runtime needs.
	# Note: Use 'mvn dependency:build-classpath' to obtain dependencies.
	{ \
	cp=`sort -u service_jars.txt messages_jars.txt` ; \
	for path in $$cp; do cp $$path $$all_jars_dir; done; \
	}

# Create a jar file that contains only the classes that are actually needed to
# run the remote service. We will omit the Spark Java classes from this calcuation
# because it is unclear which SparkJava classes are the root classes, and so
# our computation would be suspect, and spark core is only 134K.
consolidate:
	$(JAVA) -cp $(JARCON_ROOT):$(CDA_ROOT)/lib/*:$(JOPT_SIMPLE) com.cliffberg.jarcon.consolidator.JarConsolidator \
		--jarPath="$(MYSQL_DRIVER):$(all_jars_dir)/*" \
		--rootClasses=$(main_class),com.mysql.jdbc.log.StandardLogger,com.mysql.jdbc.StandardSocketFactory \
		--properties=com/mysql/jdbc/LocalizedErrorMessages.properties \
		--targetJarPath=$(consol_jar_dir)/$(CONSOL_JARS_NAME) \
		--manifestVersion="1.0.0" --createdBy="Cliff Berg"

unit_test_consol_jar:
	$(JAVA) -cp $(consol_jar_dir)/$(CONSOL_JARS_NAME):$(MavenRepository)/com/scaledmarkets/recommender-tfidf/test-unit/$(VERSION)/test-unit-$(VERSION).jar \
		unittest.TestBasic

# Place all the artifacts needed to build a consolidated image in a clean directory.
# We explicitly copy SparkJava because it is not properly consolidated by jarcon.
copy_consol_jar_to_imagebuilddir:
	rm -r -f $(ImageBuildDir)
	mkdir -p $(ImageBuildDir)
	cp $(consol_jar_dir)/$(CONSOL_JARS_NAME) $(ImageBuildDir)
	cp $(MavenRepository)/com/sparkjava/spark-core/2.5/spark-core-2.5.jar $(ImageBuildDir)
	cp Dockerfile $(ImageBuildDir)

# Place all the artifacts needed to build a regular image in a clean directory.
copy_all_jars_to_imagebuilddir:
	rm -r -f $(ImageBuildDir)
	mkdir -p $(ImageBuildDir)
	cp $(all_jars_dir)/* $(ImageBuildDir)

# Build the user similarity recommender container image.
image:
	# Check that dockerhub credentials are set.
	if [ -z $(DockerhubUserId) ]; then echo "Dockerhub credentials not set"; exit 1; fi
	# Execute docker build to create an image.
	cp Dockerfile $(ImageBuildDir)
	sudo docker build --tag=$(ImageName) $(ImageBuildDir)
	# Push image to dockerhub.
	sudo docker login -u $(DockerhubUserId) -p $(DockerhubPassword)
	sudo docker push $(ImageName)
	sudo docker logout

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
	cp=`${MVN} dependency:build-classpath --projects test-bdd | tail -n 8 | head -n 1`; \
	echo cp=$$cp; \
	${JAVA} -cp $$bdd_test_maven_build_dir/classes:$$cp bddtest.PopulateForTest; \
	}

# Deploy for running behavioral tests, using the consol-jars jar.
bdd_deploy_local_consol_jars:
	$(JAVA) -cp $(consol_jar_dir)/$(CONSOL_JARS_NAME):$(SLF4J) \
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

getdeps_bddtest:
	${MVN} dependency:build-classpath --projects test-bdd | tail -n $(mvn_spaces) | head -n 1 > bdd_jars.txt

# Display the dependencies of the behavioral tests.
showdeps_bddtest: getdeps_bddtest
	cat bdd_jars.txt

# Run BDD tests.
bdd: getdeps_bddtest
	# Use maven to determine the classpath for the test program, and then run the test program.
	{ \
	cp=`cat bdd_jars.txt`; \
	$$JAVA -cp $$bdd_test_maven_build_dir/classes:$$jar_dir/$$MESSAGES_JAR_NAME:$$cp \
		cucumber.api.cli.Main \
		--glue $(bdd_test_package) $(bdd_test_dir)/features \
		--tags @done --tags @tfidf --tags @database; \
	}

test: unit_test bdd

# Housekeeping.

clean:
	docker volume rm dbcreate

info:
	@echo "Makefile for $(PRODUCTNAME)"
