#!/usr/bin/env bash

elassandra_tests='
	  elassandra-basics
	  elassandra-config
	  elassandra-static
	'

imageTests+=(
	[elassandra]=$elassandra_tests

	[elassandra-rc]=$elassandra_tests
)