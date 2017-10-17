#
# Configurations pertaining to the build environment.
#

export maxerrs = 5

# Define locations of external resources.

export HOME := $(shell echo ~)
export MAVEN_HOME := $(HOME)/Library/apache-maven-3.3.9
export JAVA_HOME := /Library/Java/JavaVirtualMachines/jdk1.8.0_20.jdk/Contents/Home

export MAHOUT_HOME := $(HOME)/Library/apache-mahout-distribution-0.13.0
export jar_dir := /Transient/Recommenders
export CUCUMBER_HOME:=$(HOME)/Library/Cucumber
export MYSQL_JDBC_HOME := $(HOME)/Library/mysql-connector-java-5.1.44
export SparkJavaHome := $(HOME)/Library/SparkJava
export GSON_HOME := $(HOME)/Library/gson
export JERSEY_HOME := $(HOME)/Library/jersey-2.25.1
export JAVAXWS_HOME := $(HOME)/Library/J2EE/Release_8

# Define Java classpaths

MAHOUT_CP := $(MAHOUT_CP):$(MAHOUT_HOME)/mahout-integration-0.13.0.jar
MAHOUT_CP := $(MAHOUT_CP):$(MAHOUT_HOME)/mahout-math-0.13.0.jar
MAHOUT_CP := $(MAHOUT_CP):$(MAHOUT_HOME)/mahout-core-0.13.0.jar
#MAHOUT_CP := $(MAHOUT_HOME)/mahout-hdfs-0.13.0.jar
export MAHOUT_CP

CUCUMBER_CP := $(CUCUMBER_HOME)/cucumber-core-1.1.8.jar
CUCUMBER_CP := $(CUCUMBER_CP):$(CUCUMBER_HOME)/cucumber-java-1.1.8.jar
CUCUMBER_CP := $(CUCUMBER_CP):$(CUCUMBER_HOME)/cucumber-jvm-deps-1.0.3.jar
CUCUMBER_CP := $(CUCUMBER_CP):$(CUCUMBER_HOME)/gherkin-2.12.2.jar
export CUCUMBER_CP

export MYSQL_JDBC_CP := $(MYSQL_JDBC_HOME)/*
export GSON_CP := $(GSON_HOME)/*
export JERSEY_CP := $(JERSEY_HOME)/*
export JAVAXWS_CP := $(JAVAXWS_HOME)/glassfish/modules/javax.ws.rs-api.jar
