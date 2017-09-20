# docker-elassandra

Docker Image packaging for Elassandra

## Docker Hub

This image is available on [docker hub](https://hub.docker.com/r/strapdata/elassandra/)

```bash
docker pull strapdata/elassandra
```
## Usage

Works well as a single-node cluster with default parameters:
```bash
docker run --name some-elassandra strapdata/elassandra
```

Run cqlsh:
```bash
docker run -it --link some-elassandra --rm strapdata/elassandra cqlsh some-elassandra
```

Test elasticsearch http api:
```bash
docker run -it --link some-elassandra --rm strapdata/elassandra curl some-elassandra:9200
```

Exposed ports:
* 7000: intra-node communication
* 7001: TLS intra-node communication
* 7199: JMX
* 9042: CQL
* 9160: thrift service
* 9200: ElasticSearch HTTP
* 9300: ElasticSearch transport

Volume:
* /var/lib/cassandra

This docker image is based on [docker-library/cassandra](https://github.com/docker-library/cassandra).
For more complicated setups, please refer to the [documentation](https://github.com/docker-library/docs/tree/master/cassandra).


## Build from source

```bash
./build.sh 2.4.2.13
```
will create a directory `2.4.2.13/`, generate a Dockerfile, and build a docker image out of it with name `elassandra-2.4.2.13`.
