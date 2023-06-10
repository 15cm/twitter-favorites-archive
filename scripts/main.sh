#!/usr/bin/env bash

deps=(
  fd
  parallel
  jq
  wget
  realpath
)

for dep in $deps; do
  if ! which $dep > /dev/null 2>&1; then
    echo "Missing dependency: $dep"
  fi
done

dir=$(dirname "$0")
root_dir=$(dirname "${dir}")

while getopts 'o:c:n:utdm' option; do
  case "$option" in
    o)
      output_dir="$OPTARG"
      ;;
    c)
      cache_file="$OPTARG"
      ;;
    u)
      update_cache=y
      ;;
    t)
      twitter_favorites_fetching=y
      ;;
    n)
      twitter_favorites_fetching_number="$OPTARG"
      ;;
    d)
      download=y
      ;;
    m)
      metadata_update=y
      ;;
    *)
      echo "Usage : $(basename $0) <-o output_dir> [-c cache_file_for_metadata_update] [-u(update cache)] [-t(twitter favorites fetching)] [-n(twitter favorites fetching number)] [-d(download)] [-m(metadata update)]"
      echo "One of -t/-d/-m must be specified."
      exit 1
      ;;
  esac
done

if [ -z "$output_dir" ] || { [ -z "$twitter_favorites_fetching" ] && [ -z "$download" ] && [ -z "$metadata_update" ]; }; then
  echo "Usage : $(basename $0) <-o output_dir> [-c cache_file_for_metadata_update] [-u(update cache)] [-t(twitter favorites fetching)] [-n(twitter favorites fetching number)] [-d(download)] [-m(metadata update)]"
  echo "One of -t/-d/-m must be specified."
  exit 1
fi

if [ -n "$twitter_favorites_fetching" ]; then
  bundle exec "${root_dir}/src/twitter-favorites-archive.rb" meta -o="${output_dir}" -n=${twitter_favorites_fetching_number:0}
fi

if [ -n "$download" ]; then
  fd --no-ignore 'tweet\.json' "$output_dir" | parallel "${dir}/lib/download-media.sh -c \"$cache_file\" -f {}"
fi

if [ -n "$metadata_update" ]; then
  fd --no-ignore '\.(png|jpg)$' "$output_dir" | parallel "${dir}/lib/update-media-meta.sh -c \"$cache_file\" -f {}"
fi

if [ -n "$update_cache" ]; then
  fd -a --no-ignore '\.(png|jpg)$' "$output_dir" > "$cache_file"
fi
