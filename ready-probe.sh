#!/bin/bash
#
# Check for elassandra service ports
# $1=cassandra CQL port, default=9042
# $2=elasticsearch http port, default=9200

if [[ "${CASSANDRA_DAEMON:-org.apache.cassandra.service.CassandraDaemon}" == "org.apache.cassandra.service.CassandraDaemon" ]]; then
   exec grep "00000000:$(printf '%X' ${1:-9042})" /proc/net/tcp
else
   exec grep "00000000:$(printf '%X' ${2:-9200})" /proc/net/tcp
fi