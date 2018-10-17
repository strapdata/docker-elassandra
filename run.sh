#!/usr/bin/env bash

[ ! -d ~/official-images ] && git clone https://github.com/docker-library/official-images.git ~/official-images

~/official-images/test/run.sh --config ~/official-images/test/config.sh --config test/config.sh $@