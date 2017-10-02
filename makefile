# Names: -----------------------------------------------------------------------
PRODUCTNAME := TF-IDF Recommender
ORG := Scaled Markets
VERSION := 1.0
BUILD := 1234
PACKAGENAME := recommender_tfidf
EXECNAME := $(PACKAGENAME)
CPU_ARCH:=$(shell uname -s | tr '[:upper:]' '[:lower:]')_amd64
export maxerrs = 5

# References: ------------------------------------------------------------------

# http://www.solrtutorial.com/solrj-tutorial.html
# https://lucene.apache.org/solr/6_6_0/solr-core/index.html
# https://lucene.apache.org/solr/guide/6_6/index.html

# Locations: -------------------------------------------------------------------
include makefile.inc

PROJECTROOT := $(shell pwd)
SRCDIR := $(PROJECTROOT)/src
BUILDDIR := $(PROJECTROOT)/build/$(CPU_ARCH)

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


$(BUILDDIR):
	mkdir -p $(BUILDDIR)

# The compile target depends on the main executable.
# 'make compile' builds the executable, which is placed in <build_dir>.
compile:
	cargo build

build: compile $(BUILDDIR)
	if [ -z $DockerhubUserId ] then echo "Dockerhub credentials not set"; exit 1; fi
	if [ -z $ImageName ] then echo "ImageName not set"; exit 1; fi
	cp target/debug/$(EXECNAME) $BUILDDIR
	executable=$(EXECNAME) sudo docker build --tag=$ImageName $BUILDDIR
	sudo docker login -u $DockerhubUserId -p $DockerhubPassword
	sudo docker push $ImageName
	sudo docker logout

clean:
	rm -r -f $(BUILDDIR)/$(EXECNAME)
	rm -r -f target/debug/*

info:
	@echo "Makefile for $(PRODUCTNAME)"
