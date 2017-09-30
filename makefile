# Names: -----------------------------------------------------------------------
PRODUCTNAME := TF-IDF Recommender
ORG := Scaled Markets
VERSION := 1.0
BUILD := 1234
PACKAGENAME := recommender_tfidf
EXECNAME := $(PACKAGENAME)
CPU_ARCH:=$(shell uname -s | tr '[:upper:]' '[:lower:]')_amd64


# Locations: -------------------------------------------------------------------
PROJECTROOT := $(shell pwd)
BUILDSCRIPTDIR := $(PROJECTROOT)/build/Centos7
SRCDIR := $(PROJECTROOT)/src
BUILDDIR := $(PROJECTROOT)/bin
PKGDIR := $(PROJECTROOT)/pkg

# Tools: -----------------------------------------------------------------------
SHELL := /bin/sh


# Tasks: ----------------------------------------------------------------

.DEFAULT_GOAL: build
.PHONY: all compile clean info
.DELETE_ON_ERROR:
.ONESHELL:
.NOTPARALLEL:
.SUFFIXES:
.PHONY: compile cover build clean info

$(BUILDDIR):
	mkdir $(BUILDDIR)

# Main executable depends on source files.
$(BUILDDIR)/$(EXECNAME): $(BUILDDIR) $(SRCDIR)/$(PACKAGENAME)/*.go

# The compile target depends on the main executable.
# 'make compile' builds the executable, which is placed in <build_dir>.
compile: $(BUILDDIR)/$(EXECNAME)
	GOPATH=$(PROJECTROOT):$(SCANNERSDIR):$(DOCKERDIR):$(UTILITIESDIR):$(RESTDIR) go install $(PACKAGENAME)

build: compile
	if [ -z $DockerhubUserId ] then echo "Dockerhub credentials not set"; exit 1; fi
	. $BUILDDIR/common/env.sh
	cp bin/$(EXECNAME) $BUILDDIR/Centos7
	pushd build/Centos7
	executable=$(EXECNAME) sudo docker build --tag=$ImageName $BUILDDIR/Centos7
	sudo docker login -u $DockerhubUserId -p $DockerhubPassword
	sudo docker push $ImageName
	sudo docker logout

clean:
	rm -r -f $(BUILDDIR)/$(PACKAGENAME)

info:
	@echo "Makefile for $(PRODUCTNAME)"
