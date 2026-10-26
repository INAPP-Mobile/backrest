# Backrest (garethgeorge/backrest) wrapper for Railway.
#
# Why each non-default setting exists:
# - FROM pins the official image by tag AND digest:
#   garethgeorge/backrest v1.14.1, multi-arch index digest
#   sha256:b852979754281026230cc69fb11428e6d57c9a97784ab4a444ffc7934c53a215
#   (verified against the Docker Hub registry API; the amd64 manifest is
#   sha256:8c717ba795263a1802696aacce7c4e05cfbee98af80b4806ff166e6e18bde944).
#   Never :latest: a moving tag would change the server binary under
#   existing restic repositories and config.
# - USER root: Railway mounts persistent volumes root-owned; the Alpine
#   base already runs as root, and this keeps it explicit so Backrest can
#   write config, data, process logs and its .backrest-ssh dir to /data
#   without EACCES crash loops.
# - The image's own ENTRYPOINT (tini + docker-entrypoint + /backrest) is
#   preserved through entrypoint.sh, which maps Railway's injected PORT
#   to BACKREST_PORT and pins data/config onto the volume. See
#   entrypoint.sh for the full rationale.
# - No HEALTHCHECK: Railway's external healthcheckPath (/) is the check
#   that matters; an in-container HEALTHCHECK would only duplicate it.
# - No EXPOSE: the server binds Railway's injected PORT via
#   BACKREST_PORT, so a static port declaration would be a lie.
# - No CMD: entrypoint.sh execs the upstream chain itself; nothing
#   depends on the image CMD.
FROM garethgeorge/backrest:v1.14.1@sha256:b852979754281026230cc69fb11428e6d57c9a97784ab4a444ffc7934c53a215
USER root
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
LABEL org.opencontainers.image.source="https://github.com/mc9max/backrest"
LABEL org.opencontainers.image.title="Backrest"
LABEL org.opencontainers.image.description="Backrest web UI and orchestrator for restic backups, wrapped for one-click Railway deploys"
