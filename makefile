# This file should not need to be edited. Build configurations are set in
# makefile.inc.

include makefile.inc

# Names: -----------------------------------------------------------------------
PRODUCTNAME := TF-IDF Recommender
ORG := Scaled Markets
VERSION := 0.1
PROJECTNAME := recommender_tfidf
main_class := scaledmarkets.recommenders.solr.SolrSearcher
CPU_ARCH:=$(shell uname -s | tr '[:upper:]' '[:lower:]')_amd64
POP_JAR_NAME := $(PROJECTNAME)-pop.jar
SEARCH_JAR_NAME := $(PROJECTNAME)-search.jar
PopImageNae := scaledmarkets/$(PROJECTNAME)-pop
SearchImageName := scaledmarkets/$(PROJECTNAME)-search

# References: ------------------------------------------------------------------

# http://www.solrtutorial.com/solrj-tutorial.html
# https://lucene.apache.org/solr/6_6_0/solr-core/index.html
# https://lucene.apache.org/solr/guide/6_6/index.html

# Locations: -------------------------------------------------------------------

PROJECTROOT := $(shell pwd)
JAVASRCDIR := $(PROJECTROOT)/java
POPBUILDDIR := $(PROJECTROOT)/java/pop
SEARCHBUILDDIR := $(PROJECTROOT)/java/search

# Tools: -----------------------------------------------------------------------
SHELL := /bin/sh

# Java dependencies: -----------------------------------------------------------

CLASSPATH := $(SOLR_HOME)/dist/*
CLASSPATH := $(CLASSPATH):$(SOLR_HOME)/dist/solrj-lib/*

# Tasks: -----------------------------------------------------------------------

.DEFAULT_GOAL: build
.PHONY: all compile clean info
.DELETE_ON_ERROR:
.ONESHELL:
.NOTPARALLEL:
.SUFFIXES:
.PHONY: compile build clean info
.DELETE_ON_ERROR:

# Compile both the Populator and Search Java files.
compilejava:
	javac -Xmaxerrs $(maxerrs) -cp $(CLASSPATH) -d $(JAVABUILDDIR) \
		$(JAVASRCDIR)/scaledmarkets/recommenders/solr/*.java

# Create the directory into which the jars will be created.
$(jar_dir):
	mkdir -p $(jar_dir)

# Create the Populator jar.

pop_jar: $(jar_dir)/$(POP_JAR_NAME).jar

$(jar_dir)/$(POP_JAR_NAME).jar: pop_manifest compilejava $(jar_dir)
	echo "Main-Class: $(pop_main_class)" > PopManifest
	echo "Specification-Title: $(PRODUCT_NAME) Populator" >> PopManifest
	echo "Specification-Version: $(VERSION)" >> PopManifest
	echo "Specification-Vendor: $(ORG)" >> PopManifest
	echo "Implementation-Title: $(pop_main_class)" >> PopManifest
	echo "Implementation-Vendor: $(ORG)" >> PopManifest
	$(JAR) cfm $(jar_dir)/$(POP_JAR_NAME).jar PopManifest \
		-C $(POPBUILDDIR) scaledmarkets
	rm PopManifest

# Create the Search jar.

search_jar: $(jar_dir)/$(SEARCH_JAR_NAME).jar

$(jar_dir)/$(SEARCH_JAR_NAME).jar: search_manifest compilejava $(jar_dir)
	echo "Main-Class: $(search_main_class)" > SearchManifest
	echo "Specification-Title: $(PRODUCT_NAME) Searcher" >> SearchManifest
	echo "Specification-Version: $(VERSION)" >> SearchManifest
	echo "Specification-Vendor: $(ORG)" >> SearchManifest
	echo "Implementation-Title: $(search_main_class)" >> SearchManifest
	echo "Implementation-Vendor: $(ORG)" >> SearchManifest
	$(JAR) cfm $(jar_dir)/$(SEARCH_JAR_NAME).jar SearchManifest \
		-C $(SEARCHBUILDDIR) scaledmarkets
	rm SearchManifest

# Build the Populator container image.

$(POPBUILDDIR):
	mkdir -p $(POPBUILDDIR)

buildpopulator: compilejava $(POPBUILDDIR) pop_jar
	if [ -z $DockerhubUserId ] then echo "Dockerhub credentials not set"; exit 1; fi
	cp $(jar_dir)/$(POP_JAR_NAME) $(POPBUILDDIR)
	PROJECTNAME=$(PROJECTNAME) POP_JAR_NAME=$(POP_JAR_NAME) sudo docker build \
		--tag=$PopImageName $POPBUILDDIR
	sudo docker login -u $DockerhubUserId -p $DockerhubPassword
	sudo docker push $PopImageName
	sudo docker logout

# Build the Search container image.

$(SEARCHBUILDDIR):
	mkdir -p $(SEARCHBUILDDIR)

buildsearcher: compilejava $(SEARCHBUILDDIR) search_jar
	if [ -z $DockerhubUserId ] then echo "Dockerhub credentials not set"; exit 1; fi
	cp $(jar_dir)/$(SEARCH_JAR_NAME) $(SEARCHBUILDDIR)
	PROJECTNAME=$(PROJECTNAME) SEARCH_JAR_NAME=$(SEARCH_JAR_NAME) sudo docker build \
		--tag=$SearchImageName $SEARCHBUILDDIR
	sudo docker login -u $DockerhubUserId -p $DockerhubPassword
	sudo docker push $PopImageName
	sudo docker logout

# Housekeeping.

clean:
	rm -r -f $(POPBUILDDIR)/*
	rm -r -f $(SEARCHBUILDDIR)/*

info:
	@echo "Makefile for $(PRODUCTNAME)"
