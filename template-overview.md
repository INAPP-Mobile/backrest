[![Deploy on Railway](https://railway.app/button.svg)](https://railway.com/deploy/backrest?utm_campaign=backrest)

# Deploy and Host

Backrest is a web UI and orchestrator for restic, the fast, secure,
deduplicating backup engine. Deploy it on Railway in one click: one
service, one volume, no companion databases. The deploy form is
zero-field — open the public URL after deploy, create the admin account
on the first-run screen, add a repository (local, S3/B2/Azure/GCS,
SFTP, or any rclone remote), add a plan, and run your first snapshot.

## About Hosting

Hosting Backrest on Railway means the backup console runs as a single
lightweight Go process plus restic on Railway's infrastructure, with its
config, repositories metadata, and process logs on a persistent volume.
There are no companion services to babysit: no Postgres to tune, no
Redis to feed, no workers to scale. The wrapper maps Railway's injected
`PORT` to Backrest's bind address on every boot and pins the config to
`/data/config.json` on the volume, so restarts and redeploys keep the
admin account, every repository, and every backup plan. Railway
terminates TLS at the edge, and Backrest's plain HTTP listener serves
the full UI and API.

## Why Deploy

- **Restic without the CLI.** Deduplication, encryption, snapshots, and
  prune/check/forget behind a web UI with a scheduler, so backups
  happen on a schedule instead of when someone remembers a command.
- **Lightweight by design.** One Go binary plus restic; it idles on a
  fraction of a vCPU and well under 256 MB of RAM, spending CPU only
  while a backup or maintenance job runs.
- **Every backend restic supports.** Local disk, S3, Backblaze B2,
  Azure, GCS, SFTP, and every rclone remote — configured in the UI, no
  credentials baked into the image.
- **Restore from the browser.** Browse any snapshot and download or
  restore individual files without a terminal.

## Common Use Cases

- A scheduled off-site backup console: S3 or B2 repositories backing up
  a folder, a NAS share, or another server on a cron schedule with
  prune and health checks.
- A personal snapshot browser: import an existing restic repository
  and browse/restore from it without installing restic locally.
- A backup watchdog: scheduled checks, forget/prune policies, and
  notifications when a job fails, so a silent backup failure gets
  noticed.
- A staging area for data on the Railway volume itself: a
  local-backend repository for quick restores of app data (not a
  substitute for off-site backup).

## Dependencies for

Backrest on Railway depends on one persistent volume and a public
domain. Everything else — port mapping, config placement, restic
provisioning, healthchecks — is handled by the wrapper at boot.

### Deployment Dependencies

- Railway plan with persistent volumes (any paid tier; Backrest idles
  tiny and spends CPU only while jobs run).
- One volume (`backrest-data`, mounted at `/data`). No databases, no
  Redis, no workers.
- A public domain (Railway-provided is fine) for the web UI.
- For real off-site backups, storage-backend credentials (S3/B2/Azure/
  GCS/SFTP), entered in the Backrest UI — never in the template.

## Configuration

| Variable | Default | What it does |
| --- | --- | --- |
| `PORT` | injected by Railway | Mapped by the wrapper to `BACKREST_PORT` (`0.0.0.0:$PORT`). |
| `BACKREST_DATA` | `/data` | Backrest data directory on the volume. |
| `BACKREST_CONFIG` | `/data/config.json` | Admin account, repositories, plans. On the volume so restarts keep everything. |
| `BACKREST_RESTIC_COMMAND` | `/bin/restic` | Restic binary shipped in the pinned image. |
| `BACKREST_MULTIHOST_HEARTBEAT_INTERVAL` | `600s` (upstream default) | Multihost heartbeat interval; only relevant in multihost mode. |
| `TZ` | container default (UTC) | Timezone for schedule evaluation; cron expressions evaluate in container time. |
