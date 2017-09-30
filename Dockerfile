FROM docker.io/centos:7
RUN mkdir /${executable}
ADD ["${executable}", "/${executable}/"]
WORKDIR /${executable}/
#CMD [""]
