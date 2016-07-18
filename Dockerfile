FROM rawmind/k8s-tools:0.3.4-2
MAINTAINER Raul Sanchez <rawmind@gmail.com>

#Set environment
ENV SERVICE_NAME=zk \
    SERVICE_USER=zookeeper \
    SERVICE_UID=10002 \
    SERVICE_GROUP=zookeeper \
    SERVICE_GID=10002 

# Add service files
ADD root /
RUN tar xzvf ${SERVICE_ARCHIVE} -C ${SERVICE_VOLUME} ; rm ${SERVICE_ARCHIVE} \
  && cd ${SERVICE_VOLUME} \
  && tar czvf ${SERVICE_ARCHIVE} * ; rm -rf ${SERVICE_VOLUME}/*
