# Zammad devcontainer - with LDAP

A devcontainer variant that adds an OpenLDAP sidecar pre-configured for
Zammad LDAP integration testing.

## Ports

| Service | Host port | Protocol |
|---------|-----------|----------|
| LDAP    | 1389      | plain / STARTTLS |
| LDAPS   | 1636      | TLS |

## Pre-seeded directory

Base DN: `dc=foo,dc=example,dc=com`

Admin DN: `cn=admin,dc=foo,dc=example,dc=com` - password `test`

### Users (`uid` / password)

| uid       | Name          | Password  |
|-----------|---------------|-----------|
| nb        | Nicole Braun  | testnb    |
| ab        | Albert Braun  | testab    |
| bb        | Berta Braun   | testbb    |
| fb        | Frida Braun   | testfb    |
| lb        | Lena Braun    | testlb    |
| eb        | Elke Braun    | testeb    |
| customer1 | Customer 1    | testc1    |
| …         | …             | …         |
| customer8 | Customer 8    | testc8    |

### Groups (`ou=groups,dc=foo,dc=example,dc=com`)

`admin`, `1st level`, `2nd level`, `3rd level`, `4th level`, `sales`

The post-create script maps `cn=admin,ou=groups,…` → Zammad role Admin and
`cn=1st level,ou=groups,…` → Zammad role Agent.

## Configuration

Edit the `environment:` block in `.devcontainer/with-ldap/compose.yaml` and
rebuild the devcontainer (VSCode will prompt you automatically when the file
changes).

Key variables:

| Variable               | Default                      | Description |
|------------------------|------------------------------|-------------|
| `LDAP_BASE_DN`         | `dc=foo,dc=example,dc=com`   | Directory base DN |
| `LDAP_ADMIN_DN`        | `cn=admin,<LDAP_BASE_DN>`    | Admin bind DN (derived if unset) |
| `LDAP_ADMIN_PASSWORD`  | `test`                       | Admin password |
| `LDAP_DISALLOW_BIND_ANON` | `false`                  | Reject anonymous binds when `true` |

> **Note:** `.devcontainer/with-ldap/scripts/post_create.sh` also contains the
> base DN, admin DN, and admin password as hardcoded strings (in the
> `LdapSource.create!` call and `group_role_map` keys). If you change any of
> the values above in `compose.yaml`, update the corresponding values in
> `post_create.sh` as well, then rebuild the devcontainer.

## TLS certificates

A self-signed CA and server certificate are generated automatically on first
container startup into `ldap/certs/` (gitignored, only a `.gitkeep` is
committed). The post-create script imports the CA from that path into Zammad's
SSL store.

To use your own certificates, place `ca.crt`, `ldap.crt`, and `ldap.key` in
`ldap/certs/` before starting the container. The entrypoint skips generation
when `ldap.key` is already present, and the post-create script imports
`ca.crt` from that path automatically — no manual steps needed.

If you need to swap certificates on an already-running devcontainer, import
the new CA manually:

```sh
bundle exec rails r "SSLCertificate.create!(certificate: Rails.root.join('.devcontainer/with-ldap/ldap/certs/ca.crt').read)"
```

## Customising the directory seed

Edit `.devcontainer/with-ldap/ldap/bootstrap/ldif/zammad.ldif` before the
first container start. The LDIF is loaded only once (on initialisation). To
re-seed, remove the container and restart:

```sh
docker compose -f .devcontainer/with-ldap/compose.yaml rm -sv ldap
docker compose -f .devcontainer/with-ldap/compose.yaml up -d ldap
```
