#!/bin/bash

[ "$DEBUG" ] && set -x

set -eo pipefail -o errtrace

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

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
  trap "( set -x; docker logs --tail=20 $cid )" ERR

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
      -e CASSANDRA__num_tokens=5 \
      -e CASSANDRA__hinted_handoff_enabled=false \
      -e CASSANDRA__authenticator=PasswordAuthenticator \
      -e ELASTICSEARCH__http__port=9201 \
      "$image"
  )"

  trap "docker rm -vf $cid > /dev/null" EXIT
  trap "( set -x; docker logs --tail=20 $cid )" ERR

  sleep 2

  verify() {
    file=$1
    key=$2
    expected=$3
    actual="$(docker exec $cid cat $file | grep -v '#' | grep -e "$key:")"
    re=${4:-"$key: $expected"$}

    if [[ ! "$actual" =~ $re ]]; then
      echo "$file: $key not honored, expected: $expected, actual: $actual"
      docker exec $cid cat $file
      false
    fi
  }

  verify /etc/cassandra/cassandra.yaml num_tokens 5
  verify /etc/cassandra/cassandra.yaml hinted_handoff_enabled false
  verify /etc/cassandra/cassandra.yaml authenticator PasswordAuthenticator
  verify /etc/cassandra/elasticsearch.yml 'port' 9201 'port: 9201'$
}

# execute tests in sub-shells to allow trapping the containers
( test_cassandra_daemon )
( test_config_yq )