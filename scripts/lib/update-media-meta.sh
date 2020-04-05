#!/bin/bash
set -e

for dep in $deps; do
  if ! which $dep > /dev/null 2>&1; then
    echo "Missing dependency: $dep"
  fi
done
if [ $# -ne 1 ]; then
  echo "Usage: $0 <media_path>"
  exit 1
fi

file=$1
dir=$(dirname $file)
meta_file=${dir}/tweet.json

created_at=$(date -u -d"$(jq -r '.created_at' $meta_file)" +'%Y:%m:%d %H:%M:%S')
# Extract the last https://t.co url
full_text=$(jq -r '.full_text' $meta_file | perl -pe 'use utf8; s/(\shttps:\/\/t.co\/[a-zA-Z0-9]+)(?!.*\shttps:\/\/t.co\/[a-zA-Z0-9]+)//')
url=$(jq -r '.full_text' $meta_file | perl -ne '/(https:\/\/t.co\/[a-zA-Z0-9]+)(?!.*https:\/\/t.co\/[a-zA-Z0-9]+)/ && print "$1\n";')

exiftool -q -overwrite_original -DateTimeOriginal="${created_at}" -ImageDescription="${url}" -UserComment="${full_text}" $file
echo "Updated meta data of ${file}."
