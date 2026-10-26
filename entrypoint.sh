#!/bin/sh
# Backrest (garethgeorge/backrest) entrypoint for Railway.
#
# Why this script exists (read before changing it):
# - Backrest does NOT read Railway's injected PORT. It binds
#   BACKREST_PORT (upstream default 127.0.0.1:9898; the image's own
#   docker-entrypoint defaults it to 0.0.0.0:9898 only when unset). This
#   script maps PORT -> BACKREST_PORT="0.0.0.0:$PORT" on every boot, so
#   Railway's edge always has something to reach, on whatever port
#   Railway assigns.
# - Upstream's docker-entrypoint defaults put the config at
#   /config/config.json, which is NOT on a Railway volume: the first
#   restart would wipe the admin account, every repository and every
#   backup plan. This script pins BACKREST_CONFIG=/data/config.json and
#   BACKREST_DATA=/data, so all state lives on the one Railway volume
#   mounted at /data. Backrest derives its SSH dir from the config path,
#   so keys/known_hosts land at /data/.backrest-ssh automatically.
# - BACKREST_RESTIC_COMMAND=/bin/restic pins the restic binary the image
#   itself installed at build time (see upstream Dockerfile.alpine: the
#   downloaded restic is moved to /bin/restic). Without it Backrest would
#   manage (and possibly re-download) its own restic on first run.
# - First-run setup is a web form, not env vars: opening the public URL
#   the first time prompts for a username and password, which Backrest
#   stores in /data/config.json. There is deliberately no admin-password
#   template variable — the deploy form is zero-field.
# - Schedules run on container local time (UTC on Railway) unless the
#   operator sets TZ; Backrest's UI shows times in the browser's zone but
#   cron expressions evaluate in container time. Documented in README.
# - The upstream chain (tini + docker-entrypoint + /backrest) is exec'd
#   intact so signal handling and the image's own env defaulting stay as
#   upstream intended; this script only adds the Railway mappings above.
set -e

PORT="${PORT:-9898}"
export BACKREST_PORT="0.0.0.0:${PORT}"
export BACKREST_DATA="${BACKREST_DATA:-/data}"
export BACKREST_CONFIG="${BACKREST_CONFIG:-/data/config.json}"
export BACKREST_RESTIC_COMMAND="${BACKREST_RESTIC_COMMAND:-/bin/restic}"

mkdir -p /data

echo "[backrest] listening on 0.0.0.0:${PORT}, data=${BACKREST_DATA}, config=${BACKREST_CONFIG}"
exec /sbin/tini -- /docker-entrypoint /backrest
