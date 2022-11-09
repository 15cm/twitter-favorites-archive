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
# 1. download video with highest bitrate
# 2. video does not support some metadata fields, so download image too
# 3. order: video_url + video_image_url
urls=($(jq -r '.extended_entities.media // [] | map(if .type == "photo" then "\(.media_url_https)?format=jpg&name=large" elif .type == "video" then (.video_info.variants | max_by(.bitrate) | .url) + "\n" + "\(.media_url_https)?format=jpg&name=large" else .media_url_https end) | .[]' "$file"))

j=0
for ((i=0; i<${#urls[@]}; i++)); do
  url=${urls[$i]}
  if grep -q 'name=large' <<< "${url}"; then
    f="${dir}/${id}-${j}.jpg"
  elif grep -q '.mp4' <<< "${url}"; then
      url_no_params="${url%\?*}"
      f="${dir}/${id}-${j}.${url_no_params##*.}"
      # Make sure the video and photo have the same name. Useful in PhotoPrism(grouped into stacks) 
      ((j--))
  else
      url_no_params="${url%\?*}"
      f="${dir}/${id}-${j}.${url_no_params##*.}"
  fi
  if ! [ -f "$f" ]; then
    curl -fL $url -o "$f"
  else
    echo "$f" already exists. Skipped.
  fi
  ((j++))
done
