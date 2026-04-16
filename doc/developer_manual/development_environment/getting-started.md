# Getting Started

## Introduction

This guide explains how to setup a local Zammad development environment.
You can choose between two approaches:

- **[Devcontainer Setup](devcontainer-setup.md) (recommended)** - Uses a prebuilt development container for a
  ready-to-use environment. This is the quickest way to get started.
- **[Manual Setup](manual-setup.md)** - Install all dependencies directly on your machine for full control.

## Quick Start

### 1. Clone the [Zammad repository](https://github.com/zammad/zammad)

### 2. Starting the Environment

#### Devcontainer Setup

- Open the project folder in VS Code
- Click "Reopen in Container"
- The container will build automatically and start all required services

For more information, see [devcontainer setup guide](devcontainer-setup.md)

#### Manual Setup

- Follow instructions in [manual setup guide](manual-setup.md)

### 3. First-Time Initialization

- **Devcontainer setup:** Not required; the container comes preconfigured.
- **Manual setup:**
  Refer to the [development-workflow](development-workflow.md#quickly-reset-an-existing-development-database) setup.

### 4. Launching Zammad

You can start Zammad development services with:

#### Devcontainer setup

```sh
dev
```

#### Manual setup

```sh
bin/dev
```

### 5. Login

Once the application is running, open it in your browser at `http://localhost:3000` and use the default development credentials:

```text
Username / Email: admin@example.com
Password: test
```

> [!NOTE]
> The first time you launch the app, it can take a few minutes for assets to compile.
> You may see a blank browser window until this process is complete.
