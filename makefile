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
PopImageName := scaledmarkets/$(PROJECTNAME)-pop
SearchImageName := scaledmarkets/$(PROJECTNAME)-search

# References: ------------------------------------------------------------------

# http://www.solrtutorial.com/solrj-tutorial.html
# https://lucene.apache.org/solr/6_6_0/solr-core/index.html
# https://lucene.apache.org/solr/guide/6_6/index.html
# For SOLR schema, to customize ranking, see,
#	https://lucene.apache.org/solr/guide/7_0/other-schema-elements.html#similarity
# For finding similar documents, use "More Like This":
#	https://lucene.apache.org/solr/guide/6_6/morelikethis.html

# Locations: -------------------------------------------------------------------

PROJECTROOT := $(shell pwd)
JAVASRCDIR := $(PROJECTROOT)/java
POPJAVABUILDDIR := $(PROJECTROOT)/java/pop
SEARCHJAVABUILDDIR := $(PROJECTROOT)/java/search
POPIMAGEBUILDDIR := $(PROJECTROOT)/images/pop
SEARCHIMAGEBUILDDIR := $(PROJECTROOT)/images/search

# Tools: -----------------------------------------------------------------------
SHELL := /bin/sh

# Java dependencies: -----------------------------------------------------------

CLASSPATH := $(SOLR_HOME)/dist/*
CLASSPATH := $(CLASSPATH):$(SOLR_HOME)/dist/solrj-lib/*

# Tasks: -----------------------------------------------------------------------

.DEFAULT_GOAL: build
.PHONY: compile compilejava pop_jar search_jar buildpopulator buildsearcher clean info
.DELETE_ON_ERROR:
.ONESHELL:
.NOTPARALLEL:
.SUFFIXES:
.PHONY: compile build clean info
.DELETE_ON_ERROR:

compile: compilepop compilesearch

$(POPJAVABUILDDIR):
	mkdir -p $(POPJAVABUILDDIR)

compilepop: $(POPJAVABUILDDIR)
	javac -Xmaxerrs $(maxerrs) -cp $(CLASSPATH) -d $(POPJAVABUILDDIR) \
		$(JAVASRCDIR)/scaledmarkets/recommenders/solr/SolrjPopulator.java

$(SEARCHJAVABUILDDIR):
	mkdir -p $(SEARCHJAVABUILDDIR)

compilesearch: $(SEARCHJAVABUILDDIR)
	javac -Xmaxerrs $(maxerrs) -cp $(CLASSPATH) -d $(SEARCHJAVABUILDDIR) \
		$(JAVASRCDIR)/scaledmarkets/recommenders/solr/SolrJSearcher.java

# Create the directory into which the jars will be created.
$(jar_dir):
	mkdir -p $(jar_dir)

# Create the Populator jar.

pop_jar: $(jar_dir)/$(POP_JAR_NAME)

$(jar_dir)/$(POP_JAR_NAME): compilejava $(jar_dir)
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

$(jar_dir)/$(SEARCH_JAR_NAME): compilejava $(jar_dir)
	echo "Main-Class: $(search_main_class)" > SearchManifest
	echo "Specification-Title: $(PRODUCT_NAME) Searcher" >> SearchManifest
	echo "Specification-Version: $(VERSION)" >> SearchManifest
	echo "Specification-Vendor: $(ORG)" >> SearchManifest
	echo "Implementation-Title: $(search_main_class)" >> SearchManifest
	echo "Implementation-Vendor: $(ORG)" >> SearchManifest
	jar cfm $(jar_dir)/$(SEARCH_JAR_NAME) SearchManifest \
		-C $(SEARCHJAVABUILDDIR) scaledmarkets
	rm SearchManifest

# Build the Populator container image.

$(POPIMAGEBUILDDIR):
	mkdir -p $(POPIMAGEBUILDDIR)

popimage: compilejava $(POPIMAGEBUILDDIR) pop_jar
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

searchimage: compilejava $(SEARCHIMAGEBUILDDIR) search_jar
	if [ -z $(DockerhubUserId) ]; then echo "Dockerhub credentials not set"; exit 1; fi
	cp $(jar_dir)/$(SEARCH_JAR_NAME) $(SEARCHIMAGEBUILDDIR)
	PROJECTNAME=$(PROJECTNAME) SEARCH_JAR_NAME=$(SEARCH_JAR_NAME) docker build \
		--tag=$(SearchImageName) $(SEARCHIMAGEBUILDDIR)
	docker login -u $(DockerhubUserId) -p $(DockerhubPassword)
	docker push $(SearchImageName)
	docker logout

# Housekeeping.

clean:
	rm -r -f $(POPBUILDDIR)/*
	rm -r -f $(SEARCHBUILDDIR)/*

info:
	@echo "Makefile for $(PRODUCTNAME)"
