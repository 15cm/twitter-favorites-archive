#!/usr/bin/with-contenv bash

cat << EOF | crontab -
${CRON_SCHEDULE} /usr/bin/with-contenv bash -l -c \
'echo "Archiving -- \$(date)" > /var/log/twitter-favorites-archive/stdout.log \
&& cd /app \
&& ./scripts/main.sh -tdmu -o ./output -c ./output/cache.txt >> /var/log/twitter-favorites-archive/stdout.log 2>&1'
EOF
