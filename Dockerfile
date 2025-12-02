FROM ghcr.io/elorm116/my-app:v2

# Add new layers or modifications
RUN apk add --no-cache curl
#COPY new-config.conf /etc/