FROM alpine:latest

# install httpd w/one-liner for minimal layer size
# NOTE: original Dockerfile compiles httpd from source, we don't do that
# TODO: apache-mod-auth-openidc is currently in testing repo only
RUN \
  set -eux; \
  apk add --no-cache curl apache2 apache2-ssl apache2-http2 apache2-proxy apache-mod-auth-openidc \
    --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing

# add crontab for periodic httpd restart (graceful)
ADD ./crontab /var/spool/cron/crontabs/root

# https://httpd.apache.org/docs/2.4/stopping.html#gracefulstop
STOPSIGNAL SIGWINCH

# start crond, then hand over execution to httpd
ENTRYPOINT ["/bin/sh", "-c", "crond; exec /usr/sbin/httpd -DFOREGROUND"]

# https://docs.docker.com/engine/reference/builder/#healthcheck
HEALTHCHECK --start-period=5s --start-interval=1s \
  CMD curl -qf http://127.0.0.1:80/ || exit 1
