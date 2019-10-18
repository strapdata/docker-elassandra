#!/usr/bin/env bash

set -xe

process() {
  if [[ "$1" = '#'* ]]; then
    return ;
  fi

  group=$(echo $1 | cut -d';' -f1)
  name=$(echo $1 | cut -d';' -f2)
  url=$(echo $1 | cut -d';' -f 3)
  echo $group $name $url
  wget $url -O tmp.x
  mkdir ${group}_${name}
  if [[ $url = *.zip ]]; then
    unzip tmp.x -d ${group}_${name} >/dev/null
  elif [[ $url = *.tar.gz ]]; then
    tar xzf tmp.x -C ${group}_${name} >/dev/null
  fi
  rm tmp.x
}

while read line ; do process "$line" ; done