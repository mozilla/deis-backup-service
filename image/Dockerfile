FROM debian:stable

RUN apt-get update && apt-get install -y gettext-base python-pip curl git

WORKDIR /app
RUN curl -sSL -o /usr/local/bin/etcdctl https://s3-us-west-2.amazonaws.com/opdemand/etcdctl-v0.4.6  && chmod +x /usr/local/bin/etcdctl
RUN pip install python-dateutil; pip install git+https://github.com/s3tools/s3cmd
COPY backup.sh /app/backup.sh
COPY s3cfg /app/s3cfg
CMD ./backup.sh
