#!/bin/bash

set -ex

# If set, the images will be published to docker hub
PUBLISH=${PUBLISH:-false}

# Github Elassandra repository name
REPO=${REPO:-elassandra}

# If set, the images will be tagged latest
LATEST=${LATEST:-false}

# If set, the community image will be built
COMMUNITY=${COMMUNITY:-true}

# If set, the enterprise image will be built
ENTERPRISE=${ENTERPRISE:-false}

# Unless specified, publish in the public strapdata docker hub
DOCKER_REGISTRY=""

# If set, the script will prefix image names with "dev-"
DEBUG=${DEBUG:-false}
is_debug() {
  if [ "$DEBUG" = "true" ]; then
    return 0
  else
    return 1
  fi
}

# The latest strapack version for each major release
LATEST_STRAPACK_VERSION_5=5.5.0.10
LATEST_STRAPACK_VERSION_6=6.2.3.1

IMAGE_PREFIX=${IMAGE_PREFIX:-""}
if is_debug && [ "$IMAGE_PREFIX" = "" ] ; then
  IMAGE_PREFIX="dev-"
fi

# Options to add to docker build command
DOCKER_BUILD_OPTS=${DOCKER_BUILD_OPTS:-"--rm"}

# if not in debug mode, make docker build quiet
is_debug || DOCKER_BUILD_OPTS="${DOCKER_BUILD_OPTS} -q"

# the target names of the images
COMMUNITY_IMAGE=${DOCKER_REGISTRY}strapdata/${IMAGE_PREFIX}elassandra
ENTERPRISE_IMAGE=${DOCKER_REGISTRY}strapdata/${IMAGE_PREFIX}elassandra-enterprise

print_usage() {
  echo usage: $0 version
  echo example: $0 5.5.0.20
}

get_strapack_version() {
  elassandra_version=$1
  major="$(echo $elassandra_version |  sed  's/^\([0-9]\+\).*$/\1/')"
  key="LATEST_STRAPACK_VERSION_${major}"
  echo "${!key}"
}

build_and_push() {
  image=$1
  elassandra_version=$2
  dockerfile=$3

  cd $elassandra_version
  docker build $DOCKER_BUILD_OPTS -f $dockerfile -t "$image:$elassandra_version" .

  # push to docker hub if PUBLISH variable is true (replace remote_repository if you want to use this feature)
  if [ "$PUBLISH" = "true" ]; then
    docker push $image:$elassandra_version

    if [ "$LATEST" = "true" ]; then
      docker tag $image:$elassandra_version $image:latest
      docker push $image:latest
    fi
  fi
  cd ../
}


main() {
  elassandra_version=${TRAVIS_TAG}
  [ -z "${TRAVIS_TAG}" ] && elassandra_version=${1}
  if [[ "x$elassandra_version" -eq "x" ]]; then
     print_usage
     exit 1
  fi

  echo "Building docker image for elassandra version $elassandra_version"

  elassandra_url="https://github.com/strapdata/${REPO}/releases/download/v${elassandra_version}/elassandra-${elassandra_version}.tar.gz"
  mkdir -p $elassandra_version
  cp docker-entrypoint.sh $elassandra_version/
  cp ready-probe.sh $elassandra_version/
  cp logback.xml $elassandra_version/

  if [ "$COMMUNITY" = "true" ]; then
    jinja2 \
      -D flavor=community \
      -D tarball_url="$elassandra_url" \
      -D elassandra_version="$elassandra_version" \
      Dockerfile.j2 > "$elassandra_version/Dockerfile"

    build_and_push $COMMUNITY_IMAGE $elassandra_version Dockerfile
  fi

  if [ "$ENTERPRISE" = "true" ]; then
    strapack_version="$(get_strapack_version $elassandra_version)"
    strapack_url="http://packages.strapdata.com/strapdata-enterprise-${strapack_version}.zip"

    jinja2 \
      -D flavor=enterprise \
      -D tarball_url="$elassandra_url" \
      -D elassandra_version="$elassandra_version" \
      -D strapack_url="$strapack_url" \
      -D strapack_version="$strapack_version" \
      Dockerfile.j2 > "$elassandra_version/Dockerfile-enterprise"

      build_and_push $ENTERPRISE_IMAGE $elassandra_version Dockerfile-enterprise
  fi
}

main $@
