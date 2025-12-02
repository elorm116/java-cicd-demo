FROM ghcr.io/elorm116/my-app:v2

# Add new layers or modifications
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
#COPY new-config.conf /etc/