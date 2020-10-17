#!/bin/bash

# Update metadata of media files.

while getopts 'f:c:' option; do
  case "$option" in
    f)
      file="$OPTARG"
      ;;
    c)
      cache_file="$OPTARG"
      ;;
    *)
      echo "Usage : $(basename $0) <-f media_file> [-c cache_file]"
      exit 1
      ;;
  esac
done

if [ -z "$file" ]; then
  echo "Usage : $(basename $0) <-f media_file> [-c cache_file]"
  exit 1
fi

file=$(realpath "$file")
dir=$(dirname "$file")
meta_file="${dir}/tweet.json"

created_at=$(date -u -d"$(jq -r '.created_at' $meta_file)" +'%Y:%m:%d %H:%M:%S')
# Extract the last https://t.co url
full_text=$(jq -r '.full_text' "$meta_file" | perl -pe 'use utf8; s/(\shttps:\/\/t.co\/[a-zA-Z0-9]+)(?!.*\shttps:\/\/t.co\/[a-zA-Z0-9]+)//')
url=$(jq -r '.full_text' "$meta_file" | perl -ne '/(https:\/\/t.co\/[a-zA-Z0-9]+)(?!.*https:\/\/t.co\/[a-zA-Z0-9]+)/ && print "$1\n";')

if [ -z "$cache_file" ] || ! $(grep -Fqs "$file" "$cache_file"); then
  exiftool -q -overwrite_original -DateTimeOriginal="${created_at}" -ImageDescription="${url}" -UserComment="${full_text}" "$file"
  if [ $? -eq 0 ]; then
    echo "Updated meta data of $file."
  else
    echo "Error when updating meta data of $file. Returned $?"
  fi
else
  echo "$file is found in cache. Skipped."
fi
