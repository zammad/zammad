# Zammad Development Environment – Docker Command Reference

This README lists **all Docker / Docker Compose commands** you need for a clean, predictable Zammad **development** workflow.

This assumes:

* `docker-compose.dev.yml` exists
* `Dockerfile.dev` exists
* You are working from the Zammad repo root

---

## 0. One‑time prerequisites (host)

Verify Docker is working:

```bash
docker version
docker compose version
```

---

## 1. First‑time setup (clean start)

### 1.1 Stop everything and wipe old state (safe for dev)

```bash
docker compose -f docker-compose.dev.yml down -v
```

This removes:

* containers
* volumes (DB, bundle, storage)

---

### 1.2 Build the development image

```bash
docker compose -f docker-compose.dev.yml build
```

Rebuild **only** when:

* `Dockerfile.dev` changes
* system packages change
* Ruby / Node version changes

---

### 1.3 Install Ruby gems (once)

```bash
docker compose -f docker-compose.dev.yml run --rm zammad bundle install
```

Gems are stored in the `bundle` volume and persist across restarts.

---

### 1.4 Initialize Zammad (once per database)

```bash
docker compose -f docker-compose.dev.yml up zammad-init
```

This performs:

* database creation
* migrations
* seeds
* translations

Successful run ends with **exit code 0**.

---

## 2. Normal daily development

### 2.1 Start the application

```bash
docker compose -f docker-compose.dev.yml up zammad
```

Access:

```text
http://localhost:3000
```

---

### 2.2 Stop the app

```bash
docker compose -f docker-compose.dev.yml down
```

(Volumes are preserved.)

---

### 2.3 Restart only the app container

```bash
docker compose -f docker-compose.dev.yml restart zammad
```

Use this when:

* Rails crashes
* env vars change
* code reload feels stuck

---

## 3. Logs & debugging

### 3.1 Follow Rails logs

```bash
docker compose -f docker-compose.dev.yml logs -f zammad
```

### 3.2 View init logs

```bash
docker compose -f docker-compose.dev.yml logs zammad-init
```

### 3.3 View all logs

```bash
docker compose -f docker-compose.dev.yml logs -f
```

---

## 4. Rails & container interaction

### 4.1 Open a Rails console

```bash
docker compose -f docker-compose.dev.yml exec zammad rails console
```

### 4.2 Run a Rails command

```bash
docker compose -f docker-compose.dev.yml exec zammad rails r "puts Time.now"
```

### 4.3 Run a rake task

```bash
docker compose -f docker-compose.dev.yml exec zammad rake db:migrate
```

---

## 5. Verifying hot‑reload works

### 5.1 Ruby reload test

```bash
docker compose -f docker-compose.dev.yml exec zammad rails r "puts Time.now.to_f"
```

Run twice — should return immediately with different timestamps.

### 5.2 View reload test

Edit:

```text
app/views/layouts/application.html.erb
```

Change `<title>` → refresh browser.

---

## 6. Elasticsearch (optional for dev)

### 6.1 Verify Elasticsearch is disabled

```bash
docker compose -f docker-compose.dev.yml exec zammad rails r "puts Setting.get('es_url').inspect"
```

Expected:

```text
""
```

### 6.2 Re‑enable Elasticsearch (if needed)

1. Set:

```yaml
ELASTICSEARCH_ENABLED: "true"
```

2. Restart:

```bash
docker compose -f docker-compose.dev.yml restart zammad
```

---

## 7. Resetting the environment (start over)

Use this if things get weird:

```bash
docker compose -f docker-compose.dev.yml down -v
docker compose -f docker-compose.dev.yml build
docker compose -f docker-compose.dev.yml run --rm zammad bundle install
docker compose -f docker-compose.dev.yml up zammad-init
docker compose -f docker-compose.dev.yml up zammad
```

---

## 8. Golden rules (remember these)

* ❌ Do NOT rebuild on every code change
* ❌ Do NOT edit code inside containers
* ✅ Edit code locally
* ✅ Refresh browser
* ✅ Restart container only if needed

---

## 9. Mental model

* Docker image = runtime
* Volumes = state (DB, gems)
* Bind mounts = your code
* Containers = disposable

If this model holds, development stays fast and predictable.
