#!/usr/bin/with-contenv bash

cd /app && \
  bundle exec \
         ./src/twitter-favorites-archive.rb \
         init \
         --consumer-key=${TFA_CONSUMER_KEY} \
         --consumer-secret=${TFA_CONSUMER_SECRET} \
         --access-token=${TFA_ACCESS_TOKEN} \
         --access-token-secret=${TFA_ACCESS_TOKEN_SECRET} \
         --username=${TFA_USERNAME}

mkdir -p /var/log/twitter-favorites-archive
touch /var/log/twitter-favorites-archive/stdout.log
