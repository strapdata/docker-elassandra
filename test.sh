#!/bin/bash

#
# This test suite ensure that ./build.sh works correctly
#

# set -x
set -e

ASSETS="build.sh \
        docker-entrypoint.sh \
        Dockerfile.j2"

ASSERT_TOTAL_COUNT=0
ASSERT_FAILED_COUNT=0
ASSERT_PASSED_COUNT=0

assert_passed() {
  ASSERT_TOTAL_COUNT=$((ASSERT_TOTAL_COUNT+1))
  ASSERT_PASSED_COUNT=$((ASSERT_PASSED_COUNT+1))
  echo "#$ASSERT_TOTAL_COUNT PASSED: $@"
}

assert_failed() {
  ASSERT_TOTAL_COUNT=$((ASSERT_TOTAL_COUNT+1))
  ASSERT_FAILED_COUNT=$((ASSERT_FAILED_COUNT+1))
  echo "#$ASSERT_TOTAL_COUNT FAILED: $@"
}

test_summary() {
  echo "Total assertions $ASSERT_TOTAL_COUNT"
  echo "Passed assertions $ASSERT_PASSED_COUNT"
  echo "Failed assertions $ASSERT_FAILED_COUNT"
  if [ "$ASSERT_FAILED_COUNT" = "0" ]; then
    exit 0
  else
    exit 1
   fi
}

assert_file_exists() {
  if [ -f "$1" ]; then
    assert_passed "file exists $1"
  else
    assert_failed "file not exists $1"
  fi
}

assert_file_not_exists() {
  if [ -f "$1" ]; then
    assert_failed "file exists $1"
  else
    assert_passed "file not exists $1"
  fi
}

assert_directory_exists() {
  if [ -d "$1" ]; then
    assert_passed "directory exists $1"
  else
    assert_failed "directory not exists $1"
  fi
}

assert_jinja_resolved() {
  if grep  '{{\|}}\|{%\|%}' "$1"; then
    assert_failed "jinja not resolved $1"
  else
    assert_passed "jinja resolved $1"
  fi
}

assert_image_exists() {
  if docker image inspect $1; then
    assert_passed "image exists $1"
  else
    assert_failed "image not exists $1"
  fi
}

test_community() {

  version=${1:-"5.5.0.18"}
  image_name=strapdata/test-elassandra
  image="$image_name:$version"

  docker image rm -f $image


  IMAGE_PREFIX="test-" DEBUG=true COMMUNITY=true ENTERPRISE=false PUBLISH=false LATEST=false ./build.sh $version

  assert_directory_exists $version
  assert_file_exists $version/Dockerfile
  assert_jinja_resolved $version/Dockerfile
  assert_file_exists $version/docker-entrypoint.sh
  assert_file_not_exists $version/Dockerfile-enterprise
  assert_image_exists $image

  rm -rf $version
}

test_enterprise() {

  version=${1:-"5.5.0.18"}
  image_name=strapdata/test-elassandra-enterprise
  image="$image_name:$version"

  docker image rm -f $image


  IMAGE_PREFIX="test-" DEBUG=true COMMUNITY=false ENTERPRISE=true PUBLISH=false LATEST=false ./build.sh $version

  assert_directory_exists $version
  assert_file_exists $version/Dockerfile-enterprise
  assert_file_not_exists $version/Dockerfile
  assert_jinja_resolved $version/Dockerfile-enterprise
  assert_file_exists $version/docker-entrypoint.sh
  assert_image_exists $image

  rm -rf $version
}

prepare_env() {
  rm -rf .test
  mkdir -p .test
  cp $ASSETS .test/
  cd .test
}

main() {
  prepare_env

  for version in $@; do
    echo "### testing version $version ###"
    test_community $version
    test_enterprise $version
  done

  test_summary
}

main $@