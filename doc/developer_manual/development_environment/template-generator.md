# Hygen Template Generator

## Table of Contents

1. [Introduction](#introduction)
2. [Setup](#setup)
3. [Docs](#docs)
4. [Generating a Template](#generating-a-template)

## Introduction

Hygen is a powerful, extensible code generator that helps us quickly create files and boilerplate code based on
customizable templates.
This document provides an overview of how to use Hygen in Zammad, including setup, template creation, and common usage
patterns.

## Setup

To install Hygen, you need Node.js and the repo's package manager. Start by running:

```bash
pnpm generate:install
```

## Docs

[Hygen official docs](https://www.hygen.io/docs/templates/)

## Generating a template

```json
{
  "generate:generic-component": "pnpm --dir ./.dev/hygen exec hygen new generic-component",
  "generate:composable": "pnpm --dir ./.dev/hygen exec hygen new composable ",
  "generate:store": "pnpm --dir ./.dev/hygen exec hygen new store",
  "generate:view": "pnpm --dir ./.dev/hygen exec hygen new view"
}
```

**Steps:**

1. Open the terminal
2. Run the command f.e `pnpm generate:generic-component`
3. Follow the CI prompts

## Writing your own templates

Whenever finding yourself creating the same files over and over again, it's time to create a template.
To create a new template:
⬇️

**Steps:**

1. Navigate into `./dev/hygen/templates/new`
2. Create a prompt.js file
3. Add additional configurations in lib.config.js
4. Create a template file in the directory

**Note:**

- For example directory `new` -> specifies generator name
- `generic-component` -> action to be performed
