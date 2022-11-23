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

media_num=0
download_media() {
  for url in "$@"; do
    if grep -q 'name=large' <<<"${url}"; then
      f="${dir}/${id}-${media_num}.jpg"
    elif grep -q '.mp4' <<<"${url}"; then
      url_no_params="${url%\?*}"
      f="${dir}/${id}-${media_num}.${url_no_params##*.}"
      # Make sure the video and photo have the same name. Useful in PhotoPrism(grouped into stacks)
      ((media_num--))
    else
      url_no_params="${url%\?*}"
      f="${dir}/${id}-${media_num}.${url_no_params##*.}"
    fi
    if ! [ -f "$f" ]; then
      curl -fL $url -o "$f"
    else
      echo "$f" already exists. Skipped.
    fi
    ((media_num++))
  done
}

# media type. see also: https://www.rubydoc.info/gems/twitter/Twitter/Media, https://docs.tweepy.org/en/stable/v2_models.html#tweepy.Media
mapfile -t photo_urls < <(jq -r '.extended_entities.media // [] | map(if .type == "photo" then "\(.media_url_https)?format=jpg&name=large" else empty end) | .[]' "$file")
# 1. download video with highest bitrate
# 2. video does not support some metadata fields, so download image too
# 3. order: video_url + video_image_url
mapfile -t video_urls < <(jq -r '.extended_entities.media // [] | map(if .type == "video" then (.video_info.variants | max_by(.bitrate) | .url) + "\n" + "\(.media_url_https)?format=jpg&name=large" else empty end) | .[]' "$file")
mapfile -t gif_urls < <(jq -r '.extended_entities.media // [] | map(if .type == "animated_gif" then (.video_info.variants | max_by(.bitrate) | .url) + "\n" + "\(.media_url_https)?format=jpg&name=large" else empty end) | .[]' "$file")

download_media "${photo_urls[@]}"
download_media "${video_urls[@]}"
download_media "${gif_urls[@]}"
