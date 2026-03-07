# NDesk — Newbyte's Zammad Fork

Custom fork of [Zammad](https://github.com/zammad/zammad) for deep behavior changes.

## Repository

| | |
|---|---|
| **Fork** | [github.com/newbytesolucoesdigitais/ndesk](https://github.com/newbytesolucoesdigitais/ndesk) |
| **Upstream** | [github.com/zammad/zammad](https://github.com/zammad/zammad) |
| **Docker Hub** | [technewbyte/ndesk](https://hub.docker.com/r/technewbyte/ndesk) (private) |
| **Production** | `prod-ndesk` (5.161.125.64) via Cloudflare Tunnel |
| **URL** | https://ndesk.newbyte.net.br |

## Branches

| Branch | Purpose |
|---|---|
| `develop` | Default branch (from upstream, don't use) |
| `stable` | Upstream stable releases |
| `newbyte-stable` | **Our working branch** — all custom code goes here |

## CI/CD Pipeline

### How it works

```
Push to newbyte-stable  →  Build Docker image  →  Push to Docker Hub
                            (tagged: sha-<hash> + latest)
                            NO deployment

Push tag nb.X           →  Build Docker image  →  Push to Docker Hub
                            (tagged: nb.X + latest)
                         →  SSH deploy to prod-ndesk
                            (docker compose pull + up -d)
```

### Workflow file

`.github/workflows/docker-build.yml` — the only active workflow.

All upstream workflows (`ci.yaml`, `docker-ci.yaml`, `docker-release.yaml`, `packager.io.yaml`) are either disabled or can't trigger on our fork.

### GitHub Secrets

| Secret | Purpose |
|---|---|
| `DOCKERHUB_USERNAME` | Docker Hub login for pushing images |
| `DOCKERHUB_TOKEN` | Docker Hub access token |
| `SSH_PRIVATE_KEY` | Dedicated deploy key for prod-ndesk |

### Version stamping

The `VERSION` file at the repo root is patched during CI to include the release tag. Example: `7.0.0-nb.3`. This shows up in the Zammad admin panel at `/#system/version`.

## Making Releases

### 1. Develop on `newbyte-stable`

```bash
git checkout newbyte-stable
# make changes, commit, push
git push
# CI builds the image but does NOT deploy
```

### 2. Deploy when ready

```bash
git tag nb.X    # increment X from the last release
git push origin nb.X
# CI builds, pushes to Docker Hub, deploys to prod-ndesk
```

### 3. Verify

- Check the GitHub Actions run: https://github.com/newbytesolucoesdigitais/ndesk/actions
- Check the version in Zammad: https://ndesk.newbyte.net.br/#system/version
- Should show `7.0.0-nb.X`

## Syncing with Upstream

When Zammad releases a new version (e.g. 7.1.0):

```bash
git checkout newbyte-stable

# Fetch upstream changes
git fetch upstream

# Merge the new stable release
git merge upstream/stable

# Resolve any conflicts in your custom code
# ...

# Push (triggers CI build)
git push

# Test the image, then release
git tag nb.X
git push origin nb.X
```

### What to watch for during upstream sync

- **Merge conflicts** in files you've modified — resolve manually
- **Database migrations** — Zammad runs these automatically on container start
- **Elasticsearch version bumps** — may require a search index rebuild
- **Breaking changes** — check upstream release notes before merging
- **`VERSION` file** — will conflict every release; take upstream's version, our CI stamps it

### Upstream release notes

Always check before syncing:
- https://zammad.com/en/releases
- https://github.com/zammad/zammad-docker-compose/releases

## Production Server

### SSH access

```bash
ssh prod-ndesk    # defined in ~/.ssh/config
```

### Stack location

`/opt/zammad/` — cloned from [zammad-docker-compose](https://github.com/zammad/zammad-docker-compose) at tag `v15.0.2`.

### Docker Compose command

The stack uses scenario files:

```bash
docker compose -f docker-compose.yml \
  -f scenarios/add-cloudflare-tunnel.yml \
  -f scenarios/apply-resource-limits.yml \
  <command>
```

### Key files on server

| File | Purpose |
|---|---|
| `/opt/zammad/.env` | Custom config (IMAGE_REPO, VERSION, DB creds, tunnel token, resource limits) |
| `/opt/zammad/s3-backup.sh` | Daily S3 backup script |
| `/opt/zammad/docker-compose.yml` | Main compose file (from zammad-docker-compose repo) |

### Manual deploy (if CI fails)

```bash
ssh prod-ndesk
cd /opt/zammad
docker compose -f docker-compose.yml \
  -f scenarios/add-cloudflare-tunnel.yml \
  -f scenarios/apply-resource-limits.yml \
  pull
docker compose -f docker-compose.yml \
  -f scenarios/add-cloudflare-tunnel.yml \
  -f scenarios/apply-resource-limits.yml \
  up -d
```

### Rollback to official Zammad image

Edit `/opt/zammad/.env`:
```
IMAGE_REPO=ghcr.io/zammad/zammad
VERSION=7.0.0-9
```
Then pull and restart.

## Backups

- **Automated:** Zammad backup container runs daily at 3:00 AM (America/Sao_Paulo)
- **S3:** `s3-backup.sh` uploads to `s3://newbyte-backups/ndesk/`
- **Pre-upgrade snapshot:** `/opt/zammad-backup-pre-v7/` (from the 6.5→7.0 upgrade)
