#!/bin/bash

# Download media and fill its Exif meta data.

if [ $# -ne 1 ] || [ $(basename $1) != "tweet.json" ]; then
  echo "Usage: $0 <dir_path/tweet.json>"
  exit 1
fi

file=$1
dir=$(dirname $file)

id=$(jq '.id' $file)
urls=($(jq -r '.extended_entities.media // [] | map(if .type == "photo" then "\(.media_url_https)?format=jpg&name=large" else .media_url_https end) | .[]' $file))

for ((i=0; i<${#urls[@]}; i++)); do
  url=${urls[$i]}
  if grep -q 'name=large' <<< "${url}"; then
    f=${dir}/${id}-${i}.jpg
  else
      url_no_params="${url%\?*}"
      f=${dir}/${id}-${i}."${url_no_params##*.}"
  fi
  wget -c --tries=3 --waitretry=10 -O $f $url
done
