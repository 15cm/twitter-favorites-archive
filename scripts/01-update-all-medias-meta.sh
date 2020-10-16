#!/bin/bash

deps=(
  fd
  parallel
  exiftool
)

if [ $# -ne 1 ]; then
  echo "Usage: $0 <root_dir>"
  exit 1
fi

dir=$(dirname $0)

for dep in $deps; do
  if ! which $dep > /dev/null 2>&1; then
    echo "Missing dependency: $dep"
  fi
done

fd --no-ignore '\.(png|jpg)$' "$1" | parallel "${dir}/lib/update-media-meta.sh {}"
