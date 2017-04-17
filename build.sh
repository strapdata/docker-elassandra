#!/bin/bash
set -e

print_usage() {
  echo usage: $0 version build_num
  echo example: $0 2.4.2 10
}

main() {
  if [ "$#" -lt 2 ]; then
    print_usage
    exit 1
  fi

  elassandra_version=$1
  elassandra_build_num=$2
  url="https://github.com/strapdata/elassandra/releases/download/v${elassandra_version}-${elassandra_build_num}/elassandra-${elassandra_version}.tar.gz"
  mkdir -p $elassandra_version
  cp docker-entrypoint.sh $elassandra_version/
  sed 's#%%TARBALL_URL%%#'$url'#g; s/%%ELASSANDRA_VERSION%%/'$elassandra_version'/g' Dockerfile.template > "$elassandra_version/Dockerfile"
  cd $elassandra_version
  docker build -t "elassandra-$elassandra_version-$elassandra_build_num" .
}

main $@
