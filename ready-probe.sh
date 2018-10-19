#!/bin/bash
#
# Check for elassandra availability.
#

if [[ $DEBUG ]]; then
  set -x
fi

_ip_address() {
	# scrape the first non-localhost IP address of the container
	# in Swarm Mode, we often get two IPs -- the container IP, and the (shared) VIP, and the container IP should always be first
	ip address | awk '
		$1 == "inet" && $NF != "lo" {
			gsub(/\/.+$/, "", $2)
			print $2
			exit
		}
	'
}

POD_IP=${POD_IP:-$(_ip_address)}

if [[ $(nodetool status | grep ${POD_IP}) == *"UN"* ]]; then
  if [[ "${CASSANDRA_DAEMON:-org.apache.cassandra.service.CassandraDaemon}" == "org.apache.cassandra.service.CassandraDaemon" ]] || \
     curl -s -XGET "http://${POD_IP}:9200/" 2>&1 >/dev/null; then
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
