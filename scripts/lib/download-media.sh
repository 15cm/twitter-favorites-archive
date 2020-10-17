#!/bin/bash

# Download media files.

while getopts 'f:c:' option; do
  case "$option" in
    f)
      file="$OPTARG"
      ;;
    c)
      cache_file="$OPTARG"
      ;;
    *)
      echo "Usage : $(basename $0) <-f tweet_json_file> [-c cache_file]"
      exit 1
      ;;
  esac
done

if [ -z "$file" ]; then
  echo "Usage : $(basename $0) <-f tweet_json_file> [-c cache_file]"
  exit 1
fi

file=$(realpath "$file")
dir=$(dirname "$file")

id=$(jq '.id' "$file")
urls=($(jq -r '.extended_entities.media // [] | map(if .type == "photo" then "\(.media_url_https)?format=jpg&name=large" else .media_url_https end) | .[]' "$file"))

for ((i=0; i<${#urls[@]}; i++)); do
  url=${urls[$i]}
  if grep -q 'name=large' <<< "${url}"; then
    f="${dir}/${id}-${i}.jpg"
  else
      url_no_params="${url%\?*}"
      f="${dir}/${id}-${i}.${url_no_params##*.}"
  fi
  if ! [ -f "$f" ]; then
    curl -fL $url -o "$f"
  else
    echo "$f" already exists. Skipped.
  fi
done
