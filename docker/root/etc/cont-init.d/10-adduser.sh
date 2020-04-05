#!/usr/bin/with-contenv bash

PUID=${PUID:-911}
PGID=${PGID:-911}

useradd --no-create-home --shell=/bin/false abc
usermod -L abc
groupmod -o -g "$PGID" abc
usermod -o -u "$PUID" abc

echo '
-------------------------------------
GID/UID
-------------------------------------'
echo "
User uid:    $(id -u abc)
User gid:    $(id -g abc)
-------------------------------------
"
