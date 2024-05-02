#
# Check no recent JVM memory dump exists on disk.
# This requires the following JVM options:
# -XX:+HeapDumpOnOutOfMemoryError
# -XX:HeapDumpPath=/var/lib/cassandra/heapdump
#
set -x
MEMORY_DUMP_LOCATION=${MEMORY_DUMP_LOCATION:-"/var/lib/cassandra/heapdump"}
STARTUP_FILE=${STARTUP_FILE:-"/var/lib/cassandra/elassandra-0-seednode.txt"}


for f in `ls -t ${MEMORY_DUMP_LOCATION}`; do
	if [ "${MEMORY_DUMP_LOCATION}/$f" -nt $STARTUP_FILE ]; then
		echo "Found dump $f newer than $STARTUP_FILE"
	   	exit -1;
	else
		exit 0;
	fi
done