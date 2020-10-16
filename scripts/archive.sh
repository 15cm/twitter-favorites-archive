#!/bin/bash

dir=$(dirname $0)
root_dir=$(dirname ${dir})

if [ $# -ne 1 ]; then
  echo "Usage: $0 <output_dir>"
  exit 1
fi

output_dir=$1

bundle exec ${root_dir}/twitter-favorites-archive.rb meta -o=${output_dir}
${dir}/00-download-all-medias.sh ${output_dir}
${dir}/01-update-all-medias-meta.sh ${output_dir}
