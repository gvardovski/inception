#!/bin/sh

set -eu

until nc -z wordpress 9000 >/dev/null 2>&1; do
    sleep 1
done

exec nginx -g 'daemon off;'
