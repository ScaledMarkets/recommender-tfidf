#
# Configurations pertaining to the build environment.
#

export maxerrs = 5

# Define locations where we put generated content.

export jar_dir := /Transient/Recommenders

# Define locations of external resources.

export HOME := $(shell echo ~)
export MAVEN_HOME := $(HOME)/Library/apache-maven-3.3.9
export JAVA_HOME := /Library/Java/JavaVirtualMachines/jdk1.8.0_20.jdk/Contents/Home
export CUCUMBER_HOME:=$(HOME)/Library/Cucumber

# Define Java classpaths that we don't use Maven to resolve.

CUCUMBER_CP := $(CUCUMBER_HOME)/cucumber-core-1.1.8.jar
CUCUMBER_CP := $(CUCUMBER_CP):$(CUCUMBER_HOME)/cucumber-java-1.1.8.jar
CUCUMBER_CP := $(CUCUMBER_CP):$(CUCUMBER_HOME)/cucumber-jvm-deps-1.0.3.jar
CUCUMBER_CP := $(CUCUMBER_CP):$(CUCUMBER_HOME)/gherkin-2.12.2.jar
export CUCUMBER_CP
