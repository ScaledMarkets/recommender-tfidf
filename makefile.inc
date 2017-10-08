#
# Configurations pertaining to the build environment.
#

# Define locations of external resources.

export maxerrs = 5
export HOME := $(shell echo ~)
export SOLR_HOME := $(HOME)/Library/solr-7.0.0
export MAHOUT_HOME := $(HOME)/Library/apache-mahout-distribution-0.13.0
export jar_dir := /Transient/Recommenders
export CUCUMBER_HOME:=$(HOME)/Library/Cucumber
export SLF4J_HOME:=$(HOME)/Library/slf4j-1.7.25
export MYSQL_JDBC_HOME := $(HOME)/Library/mysql-connector-java-5.1.44
export SparkJavaHome := $(HOME)/Library/SparkJava
export GSON_HOME := $(HOME)/Library/gson

# Define Java classpaths

SOLR_CP := $(SOLR_HOME)/dist/*
SOLR_CP := $(SOLR_CP):$(SOLR_HOME)/dist/solrj-lib/*
export SOLR_CP

MAHOUT_CP := $(MAHOUT_HOME)/*
MAHOUT_CP := $(MAHOUT_CP):$(MAHOUT_HOME)/lib/*
#MAHOUT_CP := $(MAHOUT_HOME)/mahout-mr-0.13.0.jar
#MAHOUT_CP := $(MAHOUT_CP):$(MAHOUT_HOME)/lib/guava-14.0.1.jar
export MAHOUT_CP

CUCUMBER_CP := $(CUCUMBER_HOME)/cucumber-core-1.1.8.jar
CUCUMBER_CP := $(CUCUMBER_CP):$(CUCUMBER_HOME)/cucumber-java-1.1.8.jar
CUCUMBER_CP := $(CUCUMBER_CP):$(CUCUMBER_HOME)/cucumber-jvm-deps-1.0.3.jar
export CUCUMBER_CP := $(CUCUMBER_CP):$(CUCUMBER_HOME)/gherkin-2.12.2.jar
#CUCUMBER_CP := $(CUCUMBER_CP):$(CUCUMBER_HOME)/gherkin-jvm-deps-1.0.3.jar
export CUCUMBER_CP

#SLF4J_CP := $(SLF4J_HOME)/slf4j-api-1.7.25.jar
#SLF4J_CP := $(SLF4J_CP):$(SLF4J_HOME)/slf4j-simple-1.7.25.jar

export MYSQL_JDBC_CP := $(MYSQL_JDBC_HOME)/*
export SPARK_CP := $(SparkJavaHome)/*
export GSON_CP := $(GSON_HOME)/*
