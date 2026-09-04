# CodeGraph Setup

## Overview

CodeGraph has two independent parts:

- Agent integration registers the CodeGraph MCP server with a developer's agents. This is normally a one-time,
  machine-wide setup.
- A project index stores the source graph for one checkout in its local `.codegraph/` directory. Each checkout needs
  its own index.

Zammad pins CodeGraph as a development dependency. Use the provided pnpm scripts so setup and project commands run the
version from `package.json`.

## Connect Your Agents

Register CodeGraph with the supported agent harnesses you use:

```sh
pnpm codegraph:install
```

The installer detects supported agents, asks whether to register CodeGraph globally or only for this project, and
offers to put the `codegraph` command on `PATH`. Prefer global registration for normal development: one registration
works with every indexed project and checkout. Choose project-local registration only when you intentionally want to
limit CodeGraph to this checkout.

Accept the `PATH` offer because agent harnesses launch the MCP server with the `codegraph` command. Restart active agent
sessions after changing their MCP configuration.

Agent registration is developer-specific and is not part of the project index. Global registration is stored in each
agent's user configuration outside the repository. Project-local registration may write agent-specific files into the
checkout and must be repeated for every checkout. The root `.mcp.json` is gitignored, but review the working tree after
local setup and do not commit personal agent configuration.

## Initialize a Checkout

Build the local index from the root of each checkout:

```sh
pnpm codegraph:init
```

This creates the gitignored `.codegraph/` directory and builds the initial graph. CodeGraph then watches source files
and synchronizes the index automatically while its MCP server is running.

Devcontainers initialize their checkout during container creation, so no additional indexing command is needed there.
Agent registration remains a separate developer choice.

## Use CodeGraph

After restarting an agent, it can use the CodeGraph MCP tools whenever the current checkout contains `.codegraph/`.
CodeGraph starts the MCP server through the agent configuration; do not start `codegraph serve --mcp` manually.

To run the equivalent exploration directly in a shell, use:

```sh
pnpm exec codegraph explore "<symbol names or question>"
```

Check or rebuild the current checkout's index with:

```sh
pnpm codegraph:status
pnpm codegraph:reindex
```

## Remove CodeGraph

The two scopes are also removed separately:

```sh
pnpm codegraph:uninit     # Remove this checkout's .codegraph/ index.
pnpm codegraph:uninstall  # Remove agent integration and, unless retained, the CLI.
```

`codegraph:uninstall` does not delete project indexes. The upstream
[CodeGraph guide](https://github.com/colbymchenry/codegraph?tab=readme-ov-file#get-started) documents the installer,
project initialization, and cleanup options in detail.
