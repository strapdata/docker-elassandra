#!/bin/bash
#
# Check for elassandra availability.
#

if [[ $DEBUG ]]; then
  set -x
fi


if [[ $(nodetool status | grep ${POD_IP:=localhost}) == *"UN"* ]]; then
  if [[ "${CASSANDRA_DAEMON:-org.apache.cassandra.service.CassandraDaemon}" == "org.apache.cassandra.service.CassandraDaemon" ]] || \
     curl -s -XGET "http://localhost:9200/" 2>&1 >/dev/null; then
     exit 0;
  else 
     if [[ $DEBUG ]]; then
        echo "Elasticsearch not UP";
     fi
     exit 2;
  fi
else
  if [[ $DEBUG ]]; then
    echo "Cassandra not UP";
  fi
  exit 1;
fi
