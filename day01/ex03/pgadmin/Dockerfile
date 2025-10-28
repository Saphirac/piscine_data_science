FROM dpage/pgadmin4

# Copy servers.json to pgAdmin config directory
COPY ./servers.json /pgadmin4/servers.json

# Set environment to load the config
ENV PGADMIN_SERVER_JSON_FILE=/pgadmin4/servers.json
ENV PGADMIN_REPLACE_SERVERS_ON_STARTUP=True
