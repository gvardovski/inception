#!/bin/sh

set -eu

# Wait until wordpress resolves and accepts FastCGI connections.
until nc -z wordpress 9000 >/dev/null 2>&1; do
    sleep 1
done

exec nginx -g 'daemon off;'
