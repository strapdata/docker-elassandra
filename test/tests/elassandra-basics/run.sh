#!/bin/bash

[ "$DEBUG" ] && set -x

set -eo pipefail -o errtrace

dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

image="$1"

# Use the image being tested as our client image since it should already have curl
clientImage="$image"

# check elassandra version and commit
if [ ! -z "$ELASSANDRA_VERSION" ]; then
  [ "$(docker inspect -f  \
    '{{range $index, $value := .Config.Env}}{{println $value}}{{end}}' \
    $image | grep ELASSANDRA_VERSION)" = "ELASSANDRA_VERSION=$ELASSANDRA_VERSION" ]
else
  echo "warning: skipping elassandra version check, please set ELASSANDRA_VERSION"
fi
if [ ! -z "$ELASSANDRA_COMMIT" ]; then
  [ "$(docker inspect -f  \
    '{{range $index, $value := .Config.Env}}{{println $value}}{{end}}' \
    $image | grep ELASSANDRA_COMMIT)" = "ELASSANDRA_COMMIT=$ELASSANDRA_COMMIT" ]
else
  echo "warning: skipping elassandra commit check, please set ELASSANDRA_VERSION"
fi


# Create an instance of the container-under-test
cid="$(
	docker run -d \
		-e MAX_HEAP_SIZE='128m' \
		-e HEAP_NEWSIZE='32m' \
		"$image"
)"


cip="$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $cid)"

trap "docker rm -vf $cid > /dev/null" EXIT
trap "( set -x; docker logs --tail=20 $cid )" ERR


_status() {
	docker run --rm --link "$cid":cassandra "$clientImage" nodetool -h cassandra status
}


# like _status but use the provided ready-probe.sh script
_ready() {
  docker exec "$cid" bash -c "POD_IP=$cip /ready-probe.sh"
}

# Make sure our container is up (elassandra edit: increase timeout because elassandra need more time)
. "$dir/../../retry.sh" '_ready' -t 50

cqlsh() {
	docker run -i --rm \
		--link "$cid":cassandra \
		"$clientImage" \
		cqlsh -u cassandra -p cassandra "$@" cassandra
}


CREDENTIALS=""
PROTOCOL=http
NODE=cassandra
curl() {
	docker run -i --rm \
		--link "$cid":cassandra \
		"$clientImage" \
		curl $@
}
get() {
	docker run -i --rm \
		--link "$cid":cassandra \
		"$clientImage" \
    curl -XGET  $CREDENTIAL  "$PROTOCOL://$NODE:9200/$1" $2 $2 $4 $5 --fail
}
put() {
	docker run -i --rm \
		--link "$cid":cassandra \
		"$clientImage" \
    curl -XPUT -H Content-Type:application/json $CREDENTIAL "$PROTOCOL://$NODE:9200/$1" -d "$2" --fail
}
post() {
    docker run -i --rm \
		--link "$cid":cassandra \
		"$clientImage" \
    curl -XPOST -H Content-Type:application/json $CREDENTIAL "$PROTOCOL://$NODE:9200/$1" -d "$2" --fail
}

delete() {
   curl -XDELETE -H Content-Type:application/json $CREDENTIAL "$PROTOCOL://$NODE:9200/$1" -d "$2" --fail
}


# Make sure our container is listening
. "$dir/../../retry.sh" 'cqlsh < /dev/null'

# https://wiki.apache.org/cassandra/GettingStarted#Step_4:_Using_cqlsh

cqlsh -e "
CREATE KEYSPACE mykeyspace
	WITH REPLICATION = {
		'class': 'NetworkTopologyStrategy',
		'DC1': 1
	}
"

cqlsh -k mykeyspace -e "
CREATE TABLE users (
	user_id int PRIMARY KEY,
	fname text,
	lname text
)
"

cqlsh -k mykeyspace -e "
INSERT INTO users (user_id,  fname, lname)
	VALUES (1745, 'john', 'smith')
"
cqlsh -k mykeyspace -e "
INSERT INTO users (user_id,  fname, lname)
	VALUES (1744, 'john', 'doe')
"
cqlsh -k mykeyspace -e "
INSERT INTO users (user_id,  fname, lname)
	VALUES (1746, 'john', 'smith')
"

# TODO find some way to get cqlsh to provide machine-readable output D:
[[ "$(cqlsh -k mykeyspace -e "
SELECT * FROM users
")" == *'3 rows'* ]]

cqlsh -k mykeyspace -e "
CREATE INDEX ON users (lname)
"
[[ "$(cqlsh -k mykeyspace -e "
SELECT * FROM users WHERE lname = 'smith'
")" == *'2 rows'* ]]


# ensure elasticsearch is responding
get

# create a mapping
put "mykeyspace" '{
   "mappings" : {
      "users" : {
        "discover" : ".*",
        "properties": {}
      }
   }
}' | grep '"acknowledged":true'

# ensure index is created
get mykeyspace

# test records are indexed
tmp_output=$(get mykeyspace/users/1745)
echo $tmp_output
[ "$(echo $tmp_output | jq '.found')" = 'true' ]