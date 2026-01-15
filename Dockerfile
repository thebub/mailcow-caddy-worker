FROM alpine:latest

RUN apk add --no-cache \
    bash \
    coreutils \
    docker-cli

WORKDIR /opt/cert-copy

COPY deploy-certs.sh entrypoint.sh ./

RUN chmod +x deploy-certs.sh entrypoint.sh

ENTRYPOINT ["/opt/cert-copy/entrypoint.sh"]
