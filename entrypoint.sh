#!/bin/sh
echo "Starting cache purger..."
python3 /cache-purger.py &
echo "Starting nginx..."
/docker-entrypoint.sh nginx "-g" "daemon off;"
