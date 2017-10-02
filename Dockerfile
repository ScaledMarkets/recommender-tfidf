FROM docker.io/centos:7
RUN mkdir /${PROJECTNAME}
ADD ["${JARNAME}", "/${PROJECTNAME}/"]
WORKDIR /${PROJECTNAME}/
#CMD ["java -jar ${PROJECTNAME}/${JARNAME}"]
