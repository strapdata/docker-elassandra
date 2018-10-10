
## Elassandra docker image

This Elassandra image is available on [docker hub](https://hub.docker.com/r/strapdata/elassandra/)

[Elassandra](https://github.com/strapdata/elassandra) is a fork of [Elasticsearch](https://github.com/elastic/elasticsearch) modified to run on top of [Apache Cassandra](http://cassandra.apache.org/) in a scalable and resilient peer-to-peer architecture. Elasticsearch code is embedded in Cassanda nodes providing advanced search features on Cassandra tables and Cassandra serve as an Elasticsearch data and configuration store.

Check-out the [elassandra documentation](http://doc.elassandra.io/en/latest) for detailed instructions.

Commercial support is available from [Strapdata](https://www.strapdata.com).

## Basic usage

```bash
docker pull strapdata/elassandra
```

#### Start a single-node cluster

```bash
docker run --name el strapdata/elassandra
```

#### Connect with cqlsh

```bash
docker run -it --link el --rm strapdata/elassandra cqlsh some-elassandra
```

#### Connect to Elasticsearch API with curl

```bash
docker run -it --link el --rm strapdata/elassandra curl some-elassandra:9200
```

#### Exposed ports

* 7000: Intra-node communication
* 7001: TLS intra-node communication
* 7199: JMX
* 9042: CQL
* 9142: encrypted CQL
* 9160: thrift service
* 9200: ElasticSearch HTTP
* 9300: ElasticSearch transport

#### Volumes

* /var/lib/cassandra
* /etc/cassandra

## Advanced Usage

This image is a fork of the [Cassandra  "Official Image"](https://github.com/docker-library/cassandra) modified to run Elassandra.

We added some more features to the images, described below.

### Logging

Elassandra logging is configured with the file [logback.xml](./logback.xml)`.
It is parametrized with environment variables and thus allows to manage debug levels from your docker env section. 

```
LOGBACK_org_apache_cassandra
LOGBACK_org_apache_cassandra_service_CassandraDaemon
LOGBACK_org_elassandra_shard
LOGBACK_org_elassandra_indices
LOGBACK_org_elassandra_index
LOGBACK_org_elassandra_discovery
LOGBACK_org_elassandra_cluster_service
LOGBACK_org_elasticsearch
```

### Kubernetes

A **ready_probe.sh** script can be use for readiness probe as follow:

```yaml
  readinessProbe:
      exec:
        command: [ "/bin/bash", "-c", "/ready-probe.sh" ]
      initialDelaySeconds: 15
      timeoutSeconds: 5
```

### Configuration

All the environment variables that work for configuring the official Cassandra image continue to work here (e.g `CASSANDRA_RPC_ADDRESS`, `CASSANDRA_LISTEN_ADDRESS`...).

But for convenience, we provide an extended mechanism for configuring almost everything in **cassandra.yaml** and **elasticsearch.yml**, directly from the docker env section (except yaml arrays).

For example, to tweak the cassandra setting `server_encryption_options.keystore`, use the environment variable `CASSANDRA__server_encryption_options__keystore`.

The same apply for elasticsearch with the prefix `ELASTICSEARCH__`.

### Run cassandra only

To disable Elasticsearch, set the `CASSANDRA_DAEMON` to `org.apache.cassandra.service.CassandraDaemon`, default is `org.apache.cassandra.service.ElassandraDaemon`.

### Init script

Every `.sh` files found in `/docker-entrypoint-init.sh` will be sourced before to start elassandra.

```bash
docker run -v $(pwd)/script.sh:/docker-entrypoint-init.d/script.sh strapdata/elassandra-rc
```

## Use the build tool

Lot of parameters available, see the source [build.sh](./build.sh).

### from a local elassandra repository
```bash
REPO_DIR=../path/to/elassandra-repo ./build.sh
```

Where repo `REPO_DIR` point to an elassandra repository with debian package assembled.

### from local deb package
```bash
PACKAGE_LOCATION=../path/to/elassandra-x.x.x.x.deb ./build.sh
```

### from an url
```bash
PACKAGE_LOCATION=https://some-host.com/path/to/elassandra-x.x.x.x.deb ./build.sh
```

### from the github release page
```bash
RELEASE_NAME=6.2.3.6 ./build.sh
```
To use the elassandra-rc repo, set `RELEASE_CANDIDATE=true`.
