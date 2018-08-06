# What this is
Basic TF-IDF recommender microservice

See [Blog post](https://scaledmarkets.blogspot.com/2017/12/creating-recommender-microservice-in.html).

To do:

 * Wrap the JDBC model with the ReloadFromJDBCDataModel to load data into memory.

# To Build

All build configuration is set in env.linux (or env.mac, for my personal Mac),
and the Maven toolchain configuration file toolchains-linux.xml
(or toolchains-mac.xml for my personal Mac).

The version number is set in the makefile but must be set in each POM as well.

The makefile attempts to push the image to Dockerhub. To enable that, Dockerhub
credentials must be set through these two environment variables:

```
DockerhubUserId
DockerhubPassword
```

The makefile also sets these, which can be changed:

```
ImageName := scaledmarkets/tfidf
export ORG := Scaled Markets
export PRODUCTNAME := TF-IDF Recommender
```

The command `make regimage` will build everything, including the container image,
with all the jars on which the app depends. The command `make consolimage` will
generate a consolidated Jar file, containing only the classes that are needed.

These commands will not run tests, however. The makefile defines a separate task for
each step, so that the build can be done incrementally; these tasks are not defined to
be dependent on each other, giving you control over which execute: determing if something
out of date automatically is sometimes difficult.

There are two test suites: a unit test suite and a behavioral test suite. Each is
defined as a separate Maven module. (Yes, this is unconventional for unit tests.)

To build the image, Docker is required, and so one should perform that part of
the build in a Linux system. I have noticed difficulties running the MySQL container in Docker
under the Mac version of Docker, so I recommend booting a Linux VM and running the
tests in that - perhaps doing the whole build there. The Vagrantfile maps the output
directories so they are available from both the Mac and a VM started with Vagrant.

