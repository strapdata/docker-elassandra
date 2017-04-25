FROM debian:jessie-backports

# explicitly set user/group IDs
RUN groupadd -r cassandra --gid=999 && useradd -r -g cassandra --uid=999 cassandra

# grab gosu for easy step-down from root
ENV GOSU_VERSION 1.7
RUN set -x \
	&& apt-get update && apt-get install -y --no-install-recommends ca-certificates wget && rm -rf /var/lib/apt/lists/* \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
	&& wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
	&& gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
	&& rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
	&& chmod +x /usr/local/bin/gosu \
	&& gosu nobody true \
	&& apt-get purge -y --auto-remove ca-certificates wget

# solves warning: "jemalloc shared library could not be preloaded to speed up memory allocations"
RUN apt-get update && apt-get install -y --no-install-recommends libjemalloc1 && rm -rf /var/lib/apt/lists/*

# https://github.com/docker-library/cassandra/pull/98#issuecomment-280761137
RUN { \
		echo 'Package: openjdk-* ca-certificates-java'; \
		echo 'Pin: release n=*-backports'; \
		echo 'Pin-Priority: 990'; \
	} > /etc/apt/preferences.d/java-backports

RUN apt-get update && apt-get install -y --no-install-recommends openjdk-8-jre-headless python wget && rm -rf /var/lib/apt/lists/*

ENV ELASSANDRA_VERSION 2.4.2
ENV CASSANDRA_HOME /opt/elassandra-2.4.2
ENV CASSANDRA_CONF /opt/elassandra-2.4.2/conf
ENV CASSANDRA_PIDFILE /opt/elassandra-2.4.2/cassandra.pid

RUN wget https://github.com/strapdata/elassandra/releases/download/v2.4.2-12/elassandra-2.4.2.tar.gz -O /elassandra-$ELASSANDRA_VERSION.tar.gz
RUN cd /opt \
  && tar -xzf "/elassandra-$ELASSANDRA_VERSION.tar.gz" \
  && rm -v "/elassandra-$ELASSANDRA_VERSION.tar.gz" \
  && chown -R cassandra:cassandra "$CASSANDRA_HOME" \
  && chmod -R o-rwx "$CASSANDRA_HOME"

RUN mkdir -p /var/lib/cassandra /var/log/cassandra \
	&& chown -R cassandra:cassandra /var/lib/cassandra \
	&& chmod 750 /var/lib/cassandra /var/log/cassandra \
  && ln -s /var/lib/cassandra "$CASSANDRA_HOME"/data \
  && ln -s /var/log/cassandra "$CASSANDRA_HOME"/logs

COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

VOLUME /var/lib/cassandra

# 7000: intra-node communication
# 7001: TLS intra-node communication
# 7199: JMX
# 9042: CQL
# 9160: thrift service
# 9200: elassandra HTTP
EXPOSE 7000 7001 7199 9042 9160 9200
CMD ["bin/cassandra" ]
