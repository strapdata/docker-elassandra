#!/usr/bin/env bash

imageTests+=(
	[elassandra]='
	  elassandra-basics
    elassandra-config
	'
	[elassandra-rc]='
	  elassandra-basics
	  elassandra-config
	'
)