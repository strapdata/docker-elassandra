#!/bin/bash
set -e

print_usage() {
  echo usage: $0 version
  echo example: $0 2.4.2.13
}

main() {
  if [ "$#" -lt 1 ]; then
    print_usage
    exit 1
  fi

  elassandra_version=$1

  url="https://github.com/strapdata/elassandra/releases/download/v${elassandra_version}/elassandra-${elassandra_version}.tar.gz"
  mkdir -p $elassandra_version
  cp docker-entrypoint.sh $elassandra_version/
  sed 's#%%TARBALL_URL%%#'$url'#g; s/%%ELASSANDRA_VERSION%%/'$elassandra_version'/g' Dockerfile.template > "$elassandra_version/Dockerfile"
  cd $elassandra_version
  local_tag="elassandra-$elassandra_version"
  docker build -t "elassandra-$elassandra_version" .

  # push to docker hub if PUBLISH variable is true (replace remote_repository if you want to use this feature)
  if [ "$PUBLISH" = "true" ]; then
    remote_repository="strapdata/elassandra"
    remote_tag_list="latest $elassandra_version"
    for remote_tag in $remote_tag_list; do
      docker tag $local_tag $remote_repository:$remote_tag
      docker push $remote_repository:$remote_tag
    done
  fi

}

main $@
