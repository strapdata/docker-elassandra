
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
docker run --name my-elassandra strapdata/elassandra
```

#### Connect with cqlsh

```bash
docker exec -it my-elassandra cqlsh
```

or :

```bash
docker run -it --link my-elassandra --rm strapdata/elassandra cqlsh my-elassandra
```


#### Connect to Elasticsearch API with curl

```bash
docker exec -it my-elassandra curl localhost:9200
```

or :

```bash
docker run -it --link my-elassandra --rm strapdata/elassandra curl my-elassandra:9200
```

#### Connect to Cassandra nodetool

```bash
docker exec -it my-elassandra nodetool status
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

But for convenience, we provide an extended mechanism for configuring almost everything in **cassandra.yaml** and **elasticsearch.yml**, directly from the docker env section.

For instance, to configure cassandra `num_tokens` and elasticsearch `http.port` we do like this :

```bash
docker run \
  -e CASSANDRA__num_tokens=16 \
  -e ELASTICSEARCH__http__port=9201 \
  strapdata/elassandra
```

Notice that `__` are replaced by `.` in the generated yaml files.

It does not work to configure yaml arrays, such as cassandra seeds...

### Run cassandra only

To disable Elasticsearch, set the `CASSANDRA_DAEMON` to `org.apache.cassandra.service.CassandraDaemon`, default is `org.apache.cassandra.service.ElassandraDaemon`.

```bash
docker run \
  -e CASSANDRA_DAEMON=org.apache.cassandra.service.CassandraDaemon \
  strapdata/elassandra
```

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

The github repository is the same as the docker hub repository `REPO_NAME`, but may differs by setting `GITHUB_REPO_NAME`.

### Set the commit sha1

Use the env var `ELASSANDRA_COMMIT`. It is inserted in the image as an env var, and it's used as a tag.

### Set the registry

Use the env var `DOCKER_REGISTRY`, for instance `DOCKER_REGISTRY=gcr.io`

### troubleshooting

If you got errors such as:
```
gpg: keyserver receive failed: Cannot assign requested address
```

You can solve it by enabling this gpg server multiplexer running on docker :
```
wget -qO- 'https://github.com/tianon/pgp-happy-eyeballs/raw/master/hack-my-builds.sh' | bash
```


## Run the tests

run all:

`./run.sh strapdata/elassandra:tag`

or with debug output:

`DEBUG=true ./run.sh strapdata/elassandra:tag`

only run elassandra-basics tests:

`./run.sh -t elassandra-basics strapdata/elassandra:tag`

only run elassandra-config tests:

`./run.sh -t elassandra-config strapdata/elassandra:tag`
