FROM java:openjdk-8-jre
RUN wget -q http://mirror.nl.webzilla.com/apache/kafka/0.9.0.1/kafka_2.11-0.9.0.1.tgz -O /tmp/kafka.tgz && \
    mkdir -p /opt && \
    tar xzf /tmp/kafka.tgz -C /opt/ && \
    mv /opt/kafka* /opt/kafka  && \
    rm /tmp/kafka.tgz

RUN apt-get update  && \
    apt-get install -yq --fix-missing ruby gawk stress && \
    rm -rf /var/cache/apt

COPY kafka/start.rb /opt/start.rb

ADD ./benchmarks /benchmarks
WORKDIR /benchmarks
