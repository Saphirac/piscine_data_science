FROM dpage/pgadmin4:8

# Install envsubst
RUN apk add --no-cache gettext

# Copy template
COPY ./servers.template /tmp/servers.template

# Custom entrypoint to generate servers.json at runtime
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
