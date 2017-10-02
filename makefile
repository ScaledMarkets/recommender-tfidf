# Names: -----------------------------------------------------------------------
PRODUCTNAME := TF-IDF Recommender
ORG := Scaled Markets
VERSION := 1.0
BUILD := 1234
PROJECTNAME := recommender_tfidf
task_main_class := scaledmarkets.recommenders.solr.SolrSearcher
CPU_ARCH:=$(shell uname -s | tr '[:upper:]' '[:lower:]')_amd64
export maxerrs = 5
JAR_NAME := $(PROJECTNAME).jar

# References: ------------------------------------------------------------------

# http://www.solrtutorial.com/solrj-tutorial.html
# https://lucene.apache.org/solr/6_6_0/solr-core/index.html
# https://lucene.apache.org/solr/guide/6_6/index.html

# Locations: -------------------------------------------------------------------
include makefile.inc

PROJECTROOT := $(shell pwd)
JAVASRCDIR := $(PROJECTROOT)/java
JAVABUILDDIR := $(PROJECTROOT)/java/build

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


# Create the manifest file for the task JAR.
manifest:
	echo "Main-Class: $(task_main_class)" > Manifest
	echo "Specification-Title: $(PRODUCT_NAME)" >> Manifest
	echo "Specification-Version: $(VERSION)" >> Manifest
	echo "Specification-Vendor: $(ORG)" >> Manifest
	echo "Implementation-Title: $(task_main_class)" >> Manifest
	echo "Implementation-Vendor: $(ORG)" >> Manifest

$(JAVABUILDDIR):
	mkdir -p $(JAVABUILDDIR)

$(JAVABUILDDIR):
	mkdir -p $(JAVABUILDDIR)

$(jar_dir):
	mkdir -p $(jar_dir)

compilejava:
	javac -Xmaxerrs $(maxerrs) -cp $(CLASSPATH) -d $(JAVABUILDDIR) \
		$(JAVASRCDIR)/scaledmarkets/recommenders/solr/*.java

jar: $(jar_dir)/$(JAR_NAME).jar

$(jar_dir)/$(JAR_NAME).jar: manifest compilejava $(jar_dir)
	$(JAR) cfm $(jar_dir)/$(JAR_NAME).jar Manifest \
		-C $(JAVABUILDDIR) scaledmarkets
	rm Manifest

buildjava: compilejava $(JAVABUILDDIR) jar
	if [ -z $DockerhubUserId ] then echo "Dockerhub credentials not set"; exit 1; fi
	if [ -z $ImageName ] then echo "ImageName not set"; exit 1; fi
	cp $(jar_dir)/$(JARNAME) $(JAVABUILDDIR)
	PROJECTNAME=$(PROJECTNAME) JARNAME=$(JARNAME) sudo docker build --tag=$ImageName $JAVABUILDDIR
	sudo docker login -u $DockerhubUserId -p $DockerhubPassword
	sudo docker push $ImageName
	sudo docker logout

clean:
	rm -r -f $(JAVABUILDDIR)/*
	rm -r -f $(RUSTBUILDDIR)/*

info:
	@echo "Makefile for $(PRODUCTNAME)"
