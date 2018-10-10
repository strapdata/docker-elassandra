#!/bin/bash
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
set -ex


# The script need the elassandra git repository where the deb package has been built
REPO_DIR=${REPO_DIR}
PACKAGE_LOCATION=${PACKAGE_LOCATION}
RELEASE_NAME=${RELEASE_NAME}
RELEASE_CANDIDATE=${RELEASE_CANDIDATE:-false}
if [ -z "$REPO_DIR" ] && [ -z "$PACKAGE_LOCATION" ] && [ -z "$RELEASE_NAME" ]; then
  echo "REPO_DIR must be set to the elassandra repository directory (with debian package assembled inside)"
  echo "or PACKAGE_LOCATION must point to an url or path containing a elassandra debian package"
  echo "or RELEASE_NAME must be a valid release name on the github repository (set RELEASE_CANDIDATE=true to switch to github rc repository)"
  exit 1
fi


# If set, the images will be published to docker hub
DOCKER_PUBLISH=${DOCKER_PUBLISH:-false}

# Unless specified with a trailing slash, publish in the public strapdata docker hub
DOCKER_REGISTRY=${DOCKER_REGISTRY:-""}

# If set, the images will be tagged latest
DOCKER_LATEST=${DOCKER_LATEST:-false}

# set the docker hub repository name (by default publish on rc repository)
REPO_NAME=${REPO_NAME:-"strapdata/elassandra-rc"}

# Options to add to docker build command
DOCKER_BUILD_OPTS=${DOCKER_BUILD_OPTS:-"--rm"}

# the base image to inherit from
BASE_IMAGE=${BASE_IMAGE:-debian:stretch-slim}

# the target names of the images
DOCKER_IMAGE=${DOCKER_REGISTRY}${REPO_NAME}


wget_package() {
  local url=$1
  mkdir -p tmp-cache
  # download the deb package into the cache folder
  # the -N option ensure we do not download the file when we already have an up-to-date copy locally
  wget -N $url -P tmp-cache/
  PACKAGE_SRC=tmp-cache/$(basename $url)
}

get_release() {
  local name=$1
  local base_url

  if [ "$RELEASE_CANDIDATE" = "true" ]; then
    base_url=https://github.com/strapdata/elassandra-rc/releases/download
  else
    base_url=https://github.com/strapdata/elassandra/releases/download
  fi

  local url=$base_url/v${name}/elassandra-${name}.deb

  wget_package $url
}

if [ -n "$REPO_DIR" ]; then
  # get the first elassandra deb in the distributions folder of the git repository
  PACKAGE_SRC=$(ls ${REPO_DIR}/distribution/deb/build/distributions/elassandra-*.deb | head -n1 | cut -d " " -f1)

elif [ -n "$PACKAGE_LOCATION" ] && [[ $PACKAGE_LOCATION = http* ]]; then
  # download the file from the web
  wget_package $PACKAGE_LOCATION

elif [ -n "$PACKAGE_LOCATION" ]; then
  # simply get the file from the local disk
  PACKAGE_SRC="$PACKAGE_LOCATION"

elif [ -n "$RELEASE_NAME" ]; then
  # get the file from github release
  get_release "$RELEASE_NAME"

else
  echo "error: unreachable... you may report the issue"
  exit 1
fi

# extract the elassandra version name
ELASSANDRA_VERSION=$(echo ${PACKAGE_SRC} | sed 's/.*elassandra\-\(.*\).deb/\1/')

# setup the tmp-build directory
mkdir -p tmp-build
cp ${PACKAGE_SRC} tmp-build/
ELASSANDRA_PACKAGE=tmp-build/elassandra-${ELASSANDRA_VERSION}.deb

# build the image
echo "Building docker image for ELASSANDRA_PACKAGE=$ELASSANDRA_PACKAGE"
docker build --build-arg ELASSANDRA_VERSION=${ELASSANDRA_VERSION} \
             --build-arg ELASSANDRA_PACKAGE=${ELASSANDRA_PACKAGE} \
             --build-arg BASE_IMAGE=${BASE_IMAGE} \
             ${DOCKER_BUILD_OPTS} -f Dockerfile -t "$DOCKER_IMAGE:$ELASSANDRA_VERSION" .

# cleanup
rm -rf tmp-build

# push to docker hub if DOCKER_PUBLISH variable is true (replace remote_repository if you want to use this feature)
if [ "$DOCKER_PUBLISH" = "true" ]; then
   docker push ${DOCKER_IMAGE}:${ELASSANDRA_VERSION}

   if [ "$DOCKER_LATEST" = "true" ]; then
      echo "Publishing the latest = $ELASSANDRA_VERSION"
      docker tag ${DOCKER_IMAGE}:${ELASSANDRA_VERSION} ${DOCKER_IMAGE}:latest
      docker push ${DOCKER_IMAGE}:latest
   fi
fi