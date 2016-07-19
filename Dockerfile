FROM rawmind/k8s-tools:0.3.4-4
MAINTAINER Raul Sanchez <rawmind@gmail.com>

#Set environment
ENV SERVICE_NAME=zk \
    SERVICE_USER=zookeeper \
    SERVICE_UID=10002 \
    SERVICE_GROUP=zookeeper \
    SERVICE_GID=10002 \
    SERVICE_HOME=/opt/zk \
    SERVICE_ARCHIVE=/opt/zk-k8s-tools.tgz

# Add files
ADD root /
RUN cd ${SERVICE_VOLUME} \
  && tar czvf ${SERVICE_ARCHIVE} * ; rm -rf ${SERVICE_VOLUME}/* 