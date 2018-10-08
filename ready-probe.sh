#!/bin/bash
#
# Check for elassandra availability.
#
#set -x

if cqlsh -e "SELECT * FROM system.local" localhost 2>&1 >/dev/null; then
  if [[ "$CASSANDRA_DAEMON" == "org.apache.cassandra.service.CassandraDaemon" ]] || \
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
