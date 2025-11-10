#!/bin/bash
# Generate servers.json from template using runtime env vars
envsubst < /tmp/servers.template > /pgadmin4/servers.json
rm /tmp/servers.template

# Set env for pgAdmin to load it
export PGADMIN_SERVER_JSON_FILE=/pgadmin4/servers.json
export PGADMIN_REPLACE_SERVERS_ON_STARTUP=True

# Run original pgAdmin entrypoint
exec /usr/local/bin/docker-entrypoint.sh "$@"
