FROM codeberg.org/forgejo/forgejo:1.21
RUN apk add --no-cache curl jq su-exec netcat-openbsd ca-certificates

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]