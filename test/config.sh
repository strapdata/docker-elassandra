#!/usr/bin/env bash

elassandra_tests='
	  elassandra-basics
	  elassandra-config
	'

imageTests+=(
	[elassandra]=$elassandra_tests

	[elassandra-rc]=$elassandra_tests
)