# Backrest

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.com/deploy/backrest?utm_campaign=backrest)

Backrest is a web UI and orchestrator for [restic](https://restic.net/),
the fast, secure, deduplicating backup engine. It wraps the restic CLI
with a browser interface for creating repositories, scheduling backups
and maintenance (prune, check, forget), browsing snapshots, and
restoring files — plus notifications (Discord, Slack, Gotify, Shoutrrr,
Healthchecks) and pre/post backup hooks. This template wraps the
official `garethgeorge/backrest` image (v1.14.1, GPL-3.0) for one-click
deploys on Railway: one service, one volume, no companion databases.

## Deploy and Host

Click **Deploy on Railway** above. The deploy form is zero-field —
there is nothing to fill in. On first boot the wrapper maps Railway's
injected `PORT` to Backrest's bind address and pins all state to the
persistent volume. Open the public URL and the first-run screen prompts
for a username and password — that becomes the admin account, stored in
`/data/config.json` on the volume. Then add a repository (local,
S3/B2/Azure/GCS, SFTP, or any rclone remote), add a plan, and run your
first snapshot.

## Why Deploy

- **Restic without the CLI.** All of restic's power — deduplication,
  encryption, snapshots, prune/check/forget — behind a web UI with a
  scheduler, so backups actually happen on a schedule instead of when
  someone remembers to run a command.
- **One tiny Go binary.** Backrest is a single lightweight process plus
  restic; it idles on a fraction of a vCPU and well under 256 MB of RAM,
  and only spends CPU while a backup or maintenance job is running. It
  fits Railway's smallest tiers for a personal backup console.
- **Every backend restic supports.** Local disk, S3, Backblaze B2,
  Azure, GCS, SFTP, and every rclone remote — configure them in the UI,
  no config files, no credentials baked into the image.
- **Restore from the browser.** Browse any snapshot and download or
  restore individual files without touching a terminal.

## Common Use Cases

- A scheduled off-site backup console: point Backrest at S3 or B2 and
  back up a local folder, a NAS share, or another server's data on a
  cron schedule with prune and health checks.
- A personal snapshot browser: import an existing restic repository and
  browse/restore from it without installing restic locally.
- A backup watchdog: scheduled checks, forget/prune policies, and
  notifications when a job fails, so a silent backup failure gets
  noticed.
- A staging area for data that lives on the Railway volume itself:
  keep a local-backend repository on the volume for quick restores of
  app data (see Honest limitations — this is not off-site backup).

## Configuration

The deploy form has no fields. The wrapper consumes exactly these
variables; everything else is configured in the Backrest UI after first
run.

| Variable | Default | What it does |
| --- | --- | --- |
| `PORT` | injected by Railway | Mapped by `entrypoint.sh` to `BACKREST_PORT` (`0.0.0.0:$PORT`). Backrest does not read `PORT` itself. |
| `BACKREST_DATA` | `/data` | Backrest data directory (restic state, process logs) on the Railway volume. |
| `BACKREST_CONFIG` | `/data/config.json` | Admin account, repositories, plans, and settings. On the volume so restarts keep everything. Upstream's own default is `/config/config.json`, which would be wiped on restart — the wrapper overrides it deliberately. |
| `BACKREST_RESTIC_COMMAND` | `/bin/restic` | Restic binary shipped inside the pinned image. Without this Backrest would manage (and possibly re-download) its own restic on first run. |
| `BACKREST_PORT` | set from `PORT` by the wrapper | Bind address Backrest listens on. Do not set directly — the wrapper overwrites it from `PORT` on every boot. |
| `BACKREST_MULTIHOST_HEARTBEAT_INTERVAL` | `600s` (upstream default) | Interval for multihost heartbeat messages. Only relevant if you run Backrest in multihost mode. |
| `TZ` | container default (UTC) | Timezone used to evaluate backup schedules. Backrest's UI shows times in your browser's zone, but cron expressions evaluate in container time — set `TZ` if you want schedules in another zone. |

Upstream settings baked into the image (not template variables):
restic at `/bin/restic`, rclone and openssh available in the image for
rclone/SFTP backends, `XDG_CACHE_HOME=/cache`, `TMPDIR=/tmp`.

### Deployment Dependencies

- Railway plan with persistent volumes (any paid tier; Backrest idles
  tiny and spends CPU only while jobs run).
- One volume (`backrest-data`, mounted at `/data`). No databases, no
  Redis, no workers.
- A public domain (Railway-provided is fine) for the web UI.
- For real off-site backups, credentials for your storage backend
  (S3/B2/Azure/GCS/SFTP), entered in the Backrest UI — never in the
  template.

## Honest limitations

- **A local-backend repository on the same volume is not off-site
  backup.** It protects against accidental deletion and bad deploys,
  not against volume loss. For real disaster recovery, add an S3, B2,
  or SFTP repository in the UI.
- **Schedules evaluate in container time (UTC by default).** If you
  write a cron expression expecting local time, set `TZ` on the service
  or write the expression in UTC.
- **First-run account lives in `/data/config.json`.** Deleting the
  volume resets Backrest completely (new setup screen, no repos, no
  plans). Keep the volume.
- **Backup jobs are the only heavy work.** A large initial snapshot or
  a prune on a huge repository will use real CPU and bandwidth while it
  runs — that is the workload, not idle overhead.
