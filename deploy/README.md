# Production Deployment

This directory contains everything needed to run Zammad in production with
persistent data, daily backups, and zero data loss on container rebuild.

## Architecture in one paragraph

One Docker image built from the repo's root `Dockerfile`. That image runs in
several modes selected by `bin/docker-entrypoint`'s first argument:
`zammad-init` (schema), `zammad-railsserver` (Puma), `zammad-scheduler`
(background jobs / mail / SLA), `zammad-websocket` (live UI updates),
`zammad-nginx` (reverse proxy — the only published port), `zammad-backup`
(daily `pg_dump` + `tar`). PostgreSQL runs in its own container.

All persistent state lives in three named Docker volumes:

| Volume | What's in it | Mounted on |
|---|---|---|
| `zammad-postgresql-data` | Tickets, users, settings, sessions, articles | `zammad-postgresql:/var/lib/postgresql/data` |
| `zammad-storage`         | Uploaded files, attachments, avatars, logo | `zammad-railsserver`, `zammad-scheduler`, `zammad-websocket` at `/opt/zammad/storage` |
| `zammad-backup`          | Nightly DB + storage tar.gz archives        | `zammad-backup:/var/tmp/zammad` |

**Rebuilding the image or recreating any container does NOT touch these
volumes.** The only way to lose data is `docker volume rm`.

## First-time bootstrap

```bash
./bin/deploy-bootstrap.sh
```

That script:

1. Creates `deploy/.env` from `deploy/.env.example` (only if it doesn't exist)
2. Fills `SECRET_KEY_BASE` and `POSTGRESQL_PASS` with `openssl rand` values
3. Pauses for you to set `ZAMMAD_FQDN`, `ZAMMAD_HTTP_TYPE`, branding
4. Builds the image
5. Starts Postgres, waits for it to be healthy
6. Runs `zammad-init` (db:create / db:migrate / db:seed)
7. Runs `zammad-config` (applies fqdn / http_type / branding from env)
8. Starts the rails / scheduler / websocket / nginx / backup containers

After bootstrap, open `http://localhost:${ZAMMAD_HOST_PORT}` and complete the
admin auto-wizard at `/#getting_started`.

## Routine operations

```bash
# All compose commands take the same prefix:
DC="docker compose --env-file deploy/.env -f deploy/docker-compose.yml"

# Status
$DC ps

# Logs (any service: zammad-railsserver, zammad-scheduler, zammad-websocket, ...)
$DC logs -f zammad-railsserver

# Stop the stack — KEEPS DATA
$DC stop

# Restart
$DC up -d

# Open a Rails console
$DC exec zammad-railsserver bundle exec rails c

# Apply a new env var to running settings
$DC up --no-deps zammad-config
```

## Upgrades

```bash
git pull
docker compose --env-file deploy/.env -f deploy/docker-compose.yml build
docker compose --env-file deploy/.env -f deploy/docker-compose.yml up -d
```

What happens internally:

- `zammad-init` re-runs on container restart. On any non-empty DB it executes
  only `db:migrate` + `Locale.sync; Translation.sync` (see
  `bin/docker-entrypoint:60-84`). Idempotent.
- The app containers block on `check_zammad_ready` — they won't accept traffic
  until pending migrations finish.
- Volumes are untouched.

## Backups

### What runs automatically

The `zammad-backup` container loops once per day at `BACKUP_TIME` (default
`03:00`), writing two files into `/var/tmp/zammad` (volume `zammad-backup`):

- `${TS}_zammad_db.psql.gz` — full `pg_dump` of `zammad_production`
- `${TS}_zammad_files.tar.gz` — `tar -czf` of `/opt/zammad/storage`

Old archives older than `BACKUP_HOLD_DAYS` (default 10) are pruned.

### Ad-hoc backup

```bash
docker compose --env-file deploy/.env -f deploy/docker-compose.yml run --rm zammad-backup
```

This won't enter the scheduling loop — `contrib/docker/backup.sh` only loops
when the `restore/` subdirectory is empty *and* the container is the long-
running service. To force a one-shot today, attach to a temp container that
exits after one cycle:

```bash
docker compose --env-file deploy/.env -f deploy/docker-compose.yml exec zammad-backup \
  bash -c 'cd /opt/zammad && contrib/docker/backup.sh & sleep 30; kill %1'
```

### Copying backups off-host

The simplest pattern is to bind-mount the backup volume to a host path your
existing backup tooling already syncs:

```yaml
# Override in deploy/docker-compose.override.yml (gitignored if you create it):
services:
  zammad-backup:
    volumes:
      - /mnt/nas/zammad-backups:/var/tmp/zammad
      - zammad-storage:/opt/zammad/storage:ro
```

Or run `rclone` / `aws s3 sync` from a cron job on the host.

## Restoring from a backup

```bash
DC="docker compose --env-file deploy/.env -f deploy/docker-compose.yml"

# 1. Stop the app containers so nothing's writing to the DB during restore.
$DC stop zammad-railsserver zammad-scheduler zammad-websocket zammad-nginx

# 2. Drop the backups you want to restore into the restore/ subdir of the
#    backup volume. They MUST be named the standard way:
#    <ts>_zammad_db.psql.gz and <ts>_zammad_files.tar.gz
$DC run --rm zammad-backup bash -c 'mkdir -p /var/tmp/zammad/restore'
docker cp ./my-saved-backup_zammad_db.psql.gz    $($DC ps -q zammad-backup):/var/tmp/zammad/restore/
docker cp ./my-saved-backup_zammad_files.tar.gz  $($DC ps -q zammad-backup):/var/tmp/zammad/restore/

# 3. Trigger the restore (the backup script detects restore/ on entry).
$DC up zammad-backup
# It will: drop schema, gunzip|psql, tar -xzf, rename restore/ to restore_completed_${TS}/
# then exit. Watch the logs.

# 4. Bring the app back up.
$DC up -d
```

**Warning:** the restore runs `DROP SCHEMA PUBLIC CASCADE` before importing.
Always take a fresh backup of the current state *immediately before* a restore
so you can roll back if the backup turns out to be the wrong one.

## Redeploy-survival test (quarterly drill)

This proves volumes work end-to-end. Run it after every major change to the
compose file.

```bash
DC="docker compose --env-file deploy/.env -f deploy/docker-compose.yml"

# 1. Create a ticket with an attachment via the UI. Note the ticket number.

# 2. Confirm the ticket exists and snapshot its state:
$DC exec zammad-railsserver bundle exec rails runner '
  t = Ticket.last
  puts "before: ##{t.number} title=#{t.title.inspect} state=#{t.state.name} attachments=#{t.articles.flat_map(&:attachments).size}"
'

# 3. Recreate every app container — DO NOT touch volumes:
$DC rm -fsv zammad-railsserver zammad-scheduler zammad-websocket zammad-init zammad-nginx zammad-config
$DC up -d

# 4. After the stack settles, confirm:
$DC exec zammad-railsserver bundle exec rails runner '
  t = Ticket.last
  puts "after:  ##{t.number} title=#{t.title.inspect} state=#{t.state.name} attachments=#{t.articles.flat_map(&:attachments).size}"
'
```

Before and after should be identical. If they're not, your volumes are not
mounted where this compose file expects them.

## Migrating an existing local Zammad into this stack

If you've been running Zammad natively (rbenv + Homebrew Postgres) and want to
move that data into the Docker stack:

```bash
# 1. Dump the local DB
pg_dump -U $USER -d zammad_development | gzip > /tmp/local_zammad_db.psql.gz

# 2. Tar the local storage (if you used filesystem storage):
tar -czf /tmp/local_zammad_files.tar.gz -C / opt/zammad/storage

# 3. Bring the new stack up empty (the bootstrap above)
./bin/deploy-bootstrap.sh

# 4. Run the restore flow from the section above, supplying the two files.
```

## What env vars do what

See `deploy/.env.example` — it's heavily annotated.

| Variable | Required? | Notes |
|---|---|---|
| `SECRET_KEY_BASE` | **Yes** | Rails 8 refuses to boot without one. 128 hex chars. |
| `POSTGRESQL_PASS` | **Yes** | Override the upstream default `zammad`. |
| `ZAMMAD_FQDN` | Strongly recommended | Goes into `Setting('fqdn')` + nginx `server_name`. |
| `ZAMMAD_HTTP_TYPE` | Strongly recommended | `https` if you front with TLS. Used in absolute URLs (password-reset emails, OAuth callbacks). |
| `ELASTICSEARCH_ENABLED` | No | `false` is the safe default if you don't run ES. |
| `REDIS_URL` | No | Improves session/cache. Required if scaling websocket beyond 1 replica. |
| `RAILS_TRUSTED_PROXIES` | No | Add your LB's CIDR if you're behind one. |

## Security checklist before launch

- [ ] `deploy/.env` has `chmod 600` and is not in git (it's gitignored)
- [ ] `SECRET_KEY_BASE` is 128 random hex chars
- [ ] `POSTGRESQL_PASS` is unique, random, ≥24 chars
- [ ] `ZAMMAD_HTTP_TYPE=https` and the stack is behind a TLS terminator
- [ ] Password policy reset: see [password policy section](#password-policy)
- [ ] Test accounts purged or had their passwords rotated
- [ ] SMTP channel configured (Channels → Email in admin) — otherwise
      notifications drop silently
- [ ] One off-host backup copy verified
- [ ] Redeploy-survival test (above) passes

## Password policy

Earlier testing relaxed Zammad's password policy. To restore the
production-grade defaults:

```bash
docker compose --env-file deploy/.env -f deploy/docker-compose.yml \
  exec zammad-railsserver bundle exec rails runner '
    Setting.set("password_min_size", 10)
    Setting.set("password_min_2_lower_2_upper_characters", true)
    Setting.set("password_need_digit", true)
    puts "policy restored: min=#{Setting.get("password_min_size")} complexity=#{Setting.get("password_min_2_lower_2_upper_characters")} digit=#{Setting.get("password_need_digit")}"
'
```

To force a specific test user to rotate via the password-reset link (requires
SMTP to be configured):

```bash
docker compose --env-file deploy/.env -f deploy/docker-compose.yml \
  exec zammad-railsserver bundle exec rails runner '
    u = User.find_by(email: "waye@mports.com")
    Token.create!(action: "PasswordReset", user_id: u.id)
'
```

## What's NOT in this stack (and why)

- **Elasticsearch / OpenSearch** — disabled by default. Add via a sidecar
  service + `ELASTICSEARCH_ENABLED=true` if your ticket volume needs better
  search across article bodies.
- **Redis / Memcached** — neither is required for a single-replica stack.
  Add when you scale.
- **Mail-in via IMAP** — Zammad supports it, but it's a per-account config
  in the admin UI, not a compose service.

## Files in this directory

```
deploy/
├── docker-compose.yml   Single source of truth for the production stack.
├── .env.example         Annotated template — copy to .env (gitignored).
├── .gitignore           Keeps secrets and local backups out of git.
└── README.md            This file.
```
