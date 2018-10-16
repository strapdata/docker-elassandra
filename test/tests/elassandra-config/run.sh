#!/bin/bash

[ "$DEBUG" ] && set -x

set -eo pipefail -o errtrace

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

# Use the image being tested as our client image since it should already have curl
clientImage="$image"

# create a instance with cassandra daemon

test_cassandra_daemon() {
  local cid="$(
    docker run -d \
      -e MAX_HEAP_SIZE='128m' \
      -e HEAP_NEWSIZE='32m' \
      -e CASSANDRA_DAEMON=org.apache.cassandra.service.CassandraDaemon \
      "$image"
  )"

  trap "docker rm -vf $cid > /dev/null" EXIT

  while ! docker logs $cid | grep "Starting cassandra with"; do
    sleep 1
  done

  if [[ "$(docker logs $cid | grep 'Starting cassandra with')" == *'org.apache.cassandra.service.ElassandraDaemon'* ]]; then
    echo "CASSANDRA_DAEMON not honored"
    false
  fi
}

test_config_yq() {
  local cid="$(
    docker run -d \
      -e MAX_HEAP_SIZE='128m' \
      -e HEAP_NEWSIZE='32m' \
      -e CASSANDRA__num_token=5 \
      "$image"
  )"

  trap "docker rm -vf $cid > /dev/null" EXIT

  sleep 2

  if [[ "$(docker exec $cid cat /etc/cassandra/cassandra.yaml | grep -v '#' | grep num_token )" != *'num_token: 5'* ]]; then
    echo "CASSANDRA__num_token not honored"
    false
  fi
}

# execute tests in sub-shells to allow trapping the containers
( test_cassandra_daemon )
( test_config_yq )