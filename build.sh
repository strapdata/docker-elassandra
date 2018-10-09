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

#
# This build script runs both manually or under travis-ci
#

# If set, the images will be published to docker hub
DOCKER_PUBLISH=${DOCKER_PUBLISH:-false}

# Unless specified with a trailing slash, publish in the public strapdata docker hub
DOCKER_REGISTRY=${DOCKER_REGISTRY:-""}

# If set, the images will be tagged latest
LATEST=${LATEST:-false}

# set the docker hub repository name
REPO_NAME=${REPO_NAME:-${TRAVIS_REPO_SLUG:-"strapdata/elassandra"}}

# The script need the elassandra git repository where the deb package has been built:
REPO_DIR=${REPO_DIR:-${TRAVIS_BUILD_DIR:-"."}}

# Options to add to docker build command
DOCKER_BUILD_OPTS=${DOCKER_BUILD_OPTS:-"--rm"}

# the target names of the images
DOCKER_IMAGE=${DOCKER_REGISTRY}${REPO_NAME}

# copy the deb package to the local directory
PACKAGE_SRC=$(ls ${REPO_DIR}/distribution/deb/build/distributions/elassandra-*.deb)
ELASSANDRA_VERSION=$(echo ${PACKAGE_SRC} | sed 's/.*elassandra\-\(.*\).deb/\1/')
mkdir -p tmp-build
cp ${PACKAGE_SRC} tmp-build/
ELASSANDRA_PACKAGE=tmp-build/elassandra-${ELASSANDRA_VERSION}.deb

echo "Building docker image for ELASSANDRA_PACKAGE=$ELASSANDRA_PACKAGE"
docker build --build-arg ELASSANDRA_VERSION=${ELASSANDRA_VERSION} \
             --build-arg ELASSANDRA_PACKAGE=${ELASSANDRA_PACKAGE} \
             ${DOCKER_BUILD_OPTS} -f Dockerfile -t "$DOCKER_IMAGE:$ELASSANDRA_VERSION" .

rm -rf tmp-build

# push to docker hub if DOCKER_PUBLISH variable is true (replace remote_repository if you want to use this feature)
if [ "$DOCKER_PUBLISH" = "true" ]; then
   docker push ${DOCKER_IMAGE}:${ELASSANDRA_VERSION}

   if [ "$LATEST" = "true" ] || [ "$TRAVIS_BRANCH" = "master" ]; then
      echo "Publishing the latest = $ELASSANDRA_VERSION"
      docker tag ${DOCKER_IMAGE}:${ELASSANDRA_VERSION} ${DOCKER_IMAGE}:latest
      docker push ${DOCKER_IMAGE}:latest
   fi
fi
