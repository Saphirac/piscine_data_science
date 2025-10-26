FROM postgres:15

# Copy init scripts to initialization directory
COPY ./init /docker-entrypoint-initdb.d/

# Copy data folder to /data in image
COPY /data /data
