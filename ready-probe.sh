#!/bin/bash
#
# Check for elassandra LISTEN ports
#

if [[ "${CASSANDRA_DAEMON:-org.apache.cassandra.service.CassandraDaemon}" == "org.apache.cassandra.service.CassandraDaemon" ]]; then
   exec grep "00000000:2352" /proc/net/tcp
else
   exec grep "00000000:23F0" /proc/net/tcp
fi