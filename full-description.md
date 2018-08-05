## Official Elassandra image

Elassandra is a fork of Elasticsearch modified to run on top of Apache Cassandra in a scalable and resilient peer-to-peer architecture. Elasticsearch code is embedded in Cassanda nodes providing advanced search features on Cassandra tables and Cassandra serve as an Elasticsearch data and configuration store.
This image is available on [docker hub](https://hub.docker.com/r/strapdata/elassandra/)

This docker image is intended to support simple, single-node configuration of elassandra, essentially for testing purpose.

https://github.com/strapdata/elassandra
https://github.com/strapdata/docker-elassandra

#### Start a single-node cluster
```bash
docker run --name el strapdata/elassandra
```

#### Connect with cqlsh
```bash
docker run -it --link el --rm strapdata/elassandra cqlsh some-elassandra
```

#### Connect to Elasticsearch API with curl
```bash
docker run -it --link el --rm strapdata/elassandra curl some-elassandra:9200
```

#### Exposed ports
* 7000: intra-node communication
* 7001: TLS intra-node communication
* 7199: JMX
* 9042: CQL
* 9160: thrift service
* 9200: ElasticSearch HTTP
* 9300: ElasticSearch transport

#### Volume
* /var/lib/cassandra

#### More information

This docker image is based on [docker-library/cassandra](https://github.com/docker-library/cassandra).
For more complicated setups, please refer to the [documentation](https://github.com/docker-library/docs/tree/master/cassandra).


* A **logback.xml** with environment variables allows to manage debug levels from your docker env section. 
* For kubernetes usage, a **ready_probe.sh** script can be use for readiness probe as follow:

    readinessProbe:
        exec:
          command: [ "/bin/bash", "-c", "/ready-probe.sh" ]
        initialDelaySeconds: 15
        timeoutSeconds: 5


#### Enterprise

The `strapdata/elassandra-enterprise` image comes with the [Elassandra Enterprise](http://strapdata.com/products/) plugin pre-installed with a trial licence.

It brings more features out of the box :
* Elasticsearch through CQL
* JMX monitoring & management

And with some extra configuration, you can enable :
* Network encryption
* Authentication, authorization and audit 
* Content-based security

Check-out the [documentation](http://doc.elassandra.io/en/latest/enterprise.html) for detailed instructions.

