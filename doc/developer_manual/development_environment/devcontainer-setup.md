# Devcontainer Setup

## Overview

Zammad provides a pre-configured development container (devcontainer) for a ready-to-use development environment.

This is the **recommended** way to set up your environment, as it eliminates the need to manually install and
configure dependencies.

### Stack options

- Default
- With Mailserver (for local email testing)
- With Ollama (for local AI playground)
- With Selenium (for integration tests)

## Prerequisites

- VS Code with the Dev Containers extension (or other compatible editors / terminals).
- Docker Desktop or Docker CLI.

Ensure Docker has at least 8 GB of memory and sufficient CPU allocated.
You can configure this in Docker Desktop's settings (Settings > Resources).

## Build and Launch the Container

- Clone the [Zammad repository](https://github.com/zammad/zammad) (if you haven't already).
- Open the root of the Zammad checkout in VS Code.
  A pop-up will appear in the bottom-right corner: "Reopen in Container". Click it.
- VS Code will now build the devcontainer.

## Accessing Zammad

Once the build is complete, the container will automatically:

- Start all required services (PostgreSQL, Redis, Elasticsearch).
- Initialize and seed the database.

Open a new terminal window and start the development server:

```sh
dev
```

Access the app at [https://localhost:3000](https://localhost:3000)

The first run may take a few minutes while Rails compiles assets.
You may see a blank browser window until this is complete.

### Default Credentials

```text
Username / Email: admin@example.com
Password: test
```

## Customizing Your Development Environment

You can personalize your Zammad development container using your own dotfiles.

### Dev Container Settings

Before using dotfiles, configure the following settings in VS Code:

- `dotfiles.installCommand` - Command provided by your repository to deploy the dotfiles (for example `install.sh`)
- `dotfiles.repository` - Git repository to clone

  These settings are only available when the folder is opened locally.

The devcontainer comes with [oh-my-zsh](https://ohmyz.sh/) pre-installed,
so you can extend it with your own themes, aliases, and plugins.

> [!TIP]
> When setting this up for the first time, a container rebuild is required.

## Known Issues

### Rebase Issues on Mac

When working inside the devcontainer on mac, you might encounter problems rebasing branches.
This is due to a known issue between Docker Desktop and Git file stat checks.

You can resolve this by configuring Git to perform minimal file stat checking:

```console
git config set --system core.checkStat minimal
```

Note that this setting will not persist between container rebuilds, so you can also place it in your local .gitconfig first:

```ini
[core]
checkStat = minimal
```

## What's Next?

Now that your development environment is up and running, the next step is to get familiar with the Zammad development workflow.

Read the [Development Workflow](development-workflow.md) guide for details on testing, debugging, and contributing code.
