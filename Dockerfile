FROM fxleb/nuxeo-ffmpeg:7.10
RUN apt-get update && apt-get install -y netcat-openbsd
ADD init-nuxeo-cluster-node.sh /docker-entrypoint-initnuxeo.d/init-nuxeo-cluster-node.sh