# AI Agent Instructions

This file provides guidance on how to work with code in the Zammad repository.

## Project Overview

Zammad is an open-source helpdesk/support platform. The backend is **Ruby on Rails**.
There are two frontend stacks: the **current production frontend** is CoffeeScript
(served via the Rails asset pipeline), and the **new frontend** is **Vue 3 + TypeScript**
served via **Vite** (managed by pnpm), which is being built alongside it. **PostgreSQL** is
used for persistence, **Redis** for ActionCable/GraphQL subscriptions, and **GraphQL** is the
API layer between the new Vue apps and the backend.

## Architecture

```text
CoffeeScript frontend ──→ REST controllers ──→ Rails backend ──→ PostgreSQL
                                                    ↑
Vue 3 frontend (desktop/mobile) ──→ GraphQL API ────┘
```

New features target the Vue 3 + GraphQL stack.
The CoffeeScript frontend uses REST controllers.

## Key Directories (non-standard)

- `app/services/service/` — Service objects encapsulating business logic
- `app/graphql/gql/` — GraphQL schema, types, mutations, subscriptions
- `app/policies/` — Authorization policies (Pundit)
- `app/frontend/apps/desktop/` — Vue 3 desktop app
- `app/frontend/apps/mobile/` — Vue 3 mobile app
- `app/frontend/shared/` — Shared Vue components, composables, stores, GraphQL types, form system
- `app/assets/javascripts/` — CoffeeScript frontend (Spine + jQuery, legacy, still actively maintained)
- `lib/` — Library code, prefer minimal Rails coupling

## General Guidelines

- All new files must include the Zammad copyright header.
- Never edit translation files (`i18n/*.po`) directly —
  translations are managed via translations.zammad.org.

## Essential Commands

### Backend

```bash
RAILS_ENV=test VITE_TEST_MODE=1 bundle exec rspec spec/path/to/file_spec.rb  # Run specific RSpec test
bundle exec rubocop --autocorrect app/path/to/file.rb                        # Lint specific Ruby file(s)
```

### Frontend

Always use pnpm for frontend and cross-stack commands.

```bash
pnpm test app/frontend/path/to/file.spec.ts # Run specific Vitest test
pnpm lint                                   # Run all linters
pnpm generate-graphql-api                   # Regenerate GraphQL types after schema changes
pnpm generate-setting-types                 # Regenerate Config types after setting changes
```

## Agent Reference Docs

You MUST read the relevant file(s) below before responding when working on that area — do NOT read them all upfront:

- `.dev/agent_docs/graphql_patterns.md` — How to add/modify GraphQL types,
  mutations, queries, and subscriptions
- `.dev/agent_docs/frontend_patterns.md` — Vue component conventions,
  composables, routing, and the form system
- `.dev/agent_docs/testing.md` — How to write and run backend and frontend tests
- `.dev/agent_docs/service_patterns.md` — Service object conventions and structure
- `.dev/agent_docs/database_migrations.md` — How to write migrations and work
  with seeds
