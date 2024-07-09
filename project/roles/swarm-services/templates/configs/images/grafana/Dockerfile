FROM grafana/grafana-oss:10.2.2

USER root

RUN apk add --no-cache curl jq su-exec netcat-openbsd ca-certificates
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER 1000

ENTRYPOINT ["/entrypoint.sh"]
