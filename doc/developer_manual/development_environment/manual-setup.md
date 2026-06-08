# Manual Setup

## Overview

This guide explains how to set up a native Zammad development environment on your machine.

Use this if you prefer **not** to use the [Devcontainer Setup](devcontainer-setup.md).

**Tested environments (others may work):**

- macOS
- Debian/Ubuntu-based Linux distributions (adapt for other Linux flavors)

## System Requirements

Zammad requires the following core components to run:

- Ruby: Use the version defined in the `.ruby-version` file (recommended via rbenv or RVM)
- Node.js & PNPM: Use the version specified in `package.json` (recommended via NVM)
- Database: PostgreSQL
- Elasticsearch
- Redis

### Other Tools

The following tools are highly recommended to start hacking Zammad.

#### MacOS

```sh
brew install forego imlib2 openssl direnv geckodriver chromedriver shellcheck
```

#### Linux

```sh
sudo apt install libimlib2 libimlib2-dev openssl direnv shellcheck
```

Unfortunately there is no `forego` package / binary available for Linux. We recommend to build
it from [source](https://github.com/ddollar/forego) or alternatively use
[foreman](https://github.com/ddollar/foreman).

## Linting Tools

To ensure a well-readable and maintainable code base, we're using linting tools like:

- [CoffeeLint](http://www.coffeelint.org/)
- [Stylelint](https://stylelint.io/)
- [ESLint](https://eslint.org/)
- [Markdownlint](https://github.com/DavidAnson/markdownlint)

There is also a dependency on [Docker](https://www.docker.com/) for some linting tasks, make sure it's available on your
system.

## Using HTTPS Locally

Zammad uses the Ruby gem `localhost` to automatically generate self-signed certificates for HTTPS.

When needed, this will create:

```console
~/.local/state/localhost.rb/localhost.crt
~/.local/state/localhost.rb/localhost.key
```

To start the development server in HTTPS mode:

```sh
VITE_RUBY_HOST=0.0.0.0 VITE_RUBY_HTTPS=true RAILS_ENV=development forego start -r -f Procfile.dev-https
# or
pnpm dev:https
```

The application will be listening on [https://localhost:3000](https://localhost:3000).

### Self-Signed Certificate Notes

Most browsers will warn about self-signed certificates.
Add an exception via Advanced → Proceed (unsafe) or Accept the Risk and Continue.

In Firefox, you will also have to add an exemption for WebSocket addresses, since they use a different port. Visit:

- [https://localhost:6042](https://localhost:6042)
- [https://localhost:3036](https://localhost:3036)

and then try to reload the app.

### Using a Trusted Certificate (Let's Encrypt)

If you need a trusted HTTPS setup, you can obtain a free signed certificate via Let’s Encrypt.

For more information see:

- [Let's Encrypt - Getting Started](https://letsencrypt.org/getting-started/)
