# Zammad devcontainer - with Caddy

A devcontainer variant that adds a [Caddy](https://caddyserver.com/) reverse proxy in front of
the development stack, so the whole stack is reachable through one origin and can be exposed
through a single TLS tunnel such as [ngrok](https://ngrok.com/) - for example to open it on a
phone or to receive webhooks.

## Ports

| Service             | Port | Notes                                                         |
|---------------------|------|---------------------------------------------------------------|
| Caddy reverse proxy | 8080 | Rails, Vite dev server and legacy websocket behind one origin |

The ports of the default devcontainer (3000, 3036, 6042, 9200) stay available as well.

Caddy shares the network namespace of the devcontainer, so `localhost:8080` works inside the
devcontainer and, through the port forwarding of VS Code, on your machine.

The port only exists once this variant is running: switch to it with "Reopen in Container" and
rebuild the devcontainer after changing `compose.yaml`, `devcontainer.json` or the `Caddyfile`,
which Caddy reads at start (VS Code prompts for the rebuild when these files change).

## Usage

Start the development stack as usual:

```sh
bin/dev
```

Open <http://localhost:8080> instead of port 3000, or put a tunnel in front of it:

```sh
ngrok http 8080
```

The tunnel agent can run on your machine (against the forwarded port) or inside the devcontainer.
Caddy accepts any hostname and passes `X-Forwarded-Proto` from the tunnel through, so Rails sees
the public `https://` origin.

## Routing

| Path                          | Upstream                    | Notes                                   |
|-------------------------------|-----------------------------|-----------------------------------------|
| `/assets/frontend/vite-dev/*` | Vite dev server (`3036`)    | Assets and the HMR websocket            |
| `/ws`                         | Legacy websocket (`6042`)   | Used by the legacy frontend             |
| everything else               | Rails (`3000`)              | Includes ActionCable on `/cable`        |

Vite rejects requests whose `Host` header does not name the Vite server itself, so Caddy rewrites
the header for the Vite route - the Rails asset proxy does the same.

### Vite HMR

The Vite client normally opens its HMR websocket directly against port 3036, because the Rails
asset proxy cannot forward websocket upgrades. Through a tunnel that port does not exist. This
variant therefore sets `VITE_HMR_SAME_ORIGIN=1`, and `vite.config.mjs` then lets the client connect
to the page origin, where Caddy forwards the upgrade to Vite.

If you open the stack directly on port 3000 while the variable is set, the Vite client logs one
failed websocket connection and falls back to the direct one - use port 8080 instead.

### Legacy websocket

The post-create script sets the `websocket_backend` setting to `websocket`, so the legacy frontend
connects to `/ws` on the page origin instead of port 6042. On port 3000 it still falls back to the
port. The setting lives in the shared development database; reset it with:

```sh
bundle exec rails r "Setting.set('websocket_backend', 'websocketPort')"
```

The legacy websocket server only trusts the session cookie for configured origins (and
`localhost`). To use the legacy frontend through a tunnel, register the tunnel hostname:

```sh
bundle exec rails r "Setting.set('http_type', 'https'); Setting.set('alternative_fqdn', 'example.ngrok-free.app')"
```

`http_type=https` also marks the session cookie as secure, which Chrome and Firefox still accept
on `http://localhost`. The desktop and mobile frontends do not need this in development.

## Changing ports

Caddy listens on 8080 (`Caddyfile` and `forwardPorts` in `devcontainer.json`). The upstream ports
follow `ZAMMAD_RAILS_PORT`, `ZAMMAD_WEBSOCKET_PORT` and `VITE_RUBY_PORT`: when you move them for
`bin/dev`, set the same variables on the `caddy` service in `compose.yaml` and rebuild.
