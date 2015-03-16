FROM debian:stable

RUN apt-get update && apt-get install -y curl

CMD curl https://hq.sealabs.net/yo
