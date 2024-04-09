# Dependency setup stage
FROM python:3.11-slim as python-reqs

# Fetch requirements.txt from GitHub
ADD https://raw.githubusercontent.com/chazlarson/Media-Scripts/main/requirements.txt /requirements.txt

# Install Python dependencies
RUN apt-get update; \
    apt-get install -y gcc; \
    pip3 install --no-cache-dir -r requirements.txt

# Main image stage
FROM python:3.11-slim

# Metadata labels
LABEL maintainer="CBRHerms" \
      description="docker-media-scripts" \
      org.opencontainers.image.source="https://github.com/cbrherms/docker-media-scripts" \
      org.opencontainers.image.authors="CBRHerms" \
      org.opencontainers.image.title="docker-media-scripts"

# Copy Python packages from python-reqs stage
COPY --from=python-reqs /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages

# Set default configuration directory
ARG CONFIG_DIR=/config

# Set script environment variables
ENV CONFIG_DIR=$CONFIG_DIR
ENV TZ=Europe/London
ENV DOCKER_ENV=true

# Install additional packages
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends wget curl git tzdata jq

# Create a volume for configuration files
VOLUME $CONFIG_DIR

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh

# Copy the runscript jump script
COPY runscript.sh /usr/bin/runscript

# Make the jump script executable
RUN chmod +x /usr/bin/runscript

# Create a new user called dockeruser with default Unraid PUID and PGID
RUN groupadd -g 99 dockeruser; \
    useradd -u 100 -g 99 dockeruser; \
    chmod +x /entrypoint.sh

# Entrypoint script to start the container
ENTRYPOINT ["bash", "/entrypoint.sh"]
