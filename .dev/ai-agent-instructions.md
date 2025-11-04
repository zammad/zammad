# Onboarding for AI Agents

Purpose: Give an AI coding agent a fast, reliable mental model of this repo to ship changes with minimal trial-and-error.

## Summary

- Zammad is an open-source helpdesk/customer support platform.
  It’s a Ruby on Rails app with two modern Vue 3 frontends (desktop-view and mobile)
  and one legacy desktop-app under app/assets.
- For authoritative setup, runtime, and environment details, always refer to:
  - [`../doc/developer_manual/`](../doc/developer_manual/) (index: [`../doc/developer_manual/index.md`](../doc/developer_manual/index.md))
  - [`../package.json`](../package.json), [`../Gemfile`](../Gemfile), [`../config/database.yml`](../config/database.yml),
    [`../Procfile.dev`](../Procfile.dev), [`../vite.config.mjs`](../vite.config.mjs), [`../tsconfig.base.json`](../tsconfig.base.json),
    [`../.oxlintrc.json`](../eslint.config.ts), and other config files in the repo.
- Apps:
  - desktop-app (legacy, [`../app/assets`](../app/assets)): legacy UI using REST API + CoffeeScript/Sprockets.
    Uses the Spine.js MVC framework for frontend structure and state management.
  - desktop-view ([`../app/frontend/apps/desktop`](../app/frontend/apps/desktop)): new UI using Vue + GraphQL.
  - mobile ([`../app/frontend/apps/mobile`](../app/frontend/apps/mobile)): new UI using Vue + GraphQL.

## Tech stack (see configs for details)

- Legacy desktop-app: CoffeeScript, Spine.js, Sprockets, REST API
  (see [`../app/assets/`](../app/assets/), [`../coffeelint.json`](../coffeelint.json), QUnit in `../test/`)
- New desktop-view and mobile apps: Vue 3, TypeScript, Pinia, Apollo Client (GraphQL), Tailwind CSS, VueUse,
  Vitest, Testing Library, Cypress, pnpm, vite-plugin-ruby, vite-plugin-pwa, ESLint, Stylelint, Prettier
  (see [`../package.json`](../package.json), [`../vite.config.mjs`](../vite.config.mjs),
  [`../tsconfig.base.json`](../tsconfig.base.json), [`../eslint.config.ts`](../eslint.config.ts))
- Backend: Ruby on Rails, PostgreSQL, Redis, ActionCable, Delayed Job, GraphQL
  (see [`../Gemfile`](../Gemfile), [`../config/`](../config/))

## Project structure (high-level)

- [`../app/assets/`](../app/assets/): legacy desktop-app (CoffeeScript/Sprockets)
- [`../app/frontend/`](../app/frontend/): Vue + TS frontends
- [`../app/frontend/apps/desktop`](../app/frontend/apps/desktop),
  [`../app/frontend/apps/mobile`](../app/frontend/apps/mobile): app-specific code
- [`../app/frontend/shared/`](../app/frontend/shared/): cross-app modules (components, utils, stores, graphql, i18n)
- [`../app/frontend/tests/`](../app/frontend/tests/): vitest setup and helpers
- Rails standard: [`../app/controllers/`](../app/controllers/), [`../app/models/`](../app/models/), [`../app/views/`](../app/views/),
  [`../app/jobs/`](../app/jobs/), [`../app/mailers/`](../app/mailers/), [`../app/helpers/`](../app/helpers/), [`../app/channels/`](../app/channels/),
  [`../app/policies/`](../app/policies/)
- [`../app/services/`](../app/services/): business logic modules (not Rails standard, but common)
- [`../app/graphql/`](../app/graphql/): GraphQL API definitions and resolvers
- Other key folders: [`../bin/`](../bin/), [`../config/`](../config/), [`../db/`](../db/), [`../doc/developer_manual/`](../doc/developer_manual/),
  [`../script/`](../script/), [`../spec/`](../spec/), [`../test/`](../test/)

## lib/ directory overview

- The [`../lib/`](../lib/) directory contains core extensions, helpers, integrations, and business logic modules
  that are not part of the Rails standard structure but are essential for Zammad's backend functionality.
- It includes:
  - **Helpers and utilities:** e.g., `email_helper.rb`, `migration_helper.rb`, `sql_helper.rb`, `image_helper.rb`,
    `time_range_helper.rb`, `session_helper.rb`, `notification_factory.rb`, and more.
  - **Integrations:** Subfolders and files for external services such as `github/`, `gitlab/`, `microsoft_graph/`,
    `facebook.rb`, `telegram_helper.rb`, `whatsapp/`, and others.
  - **Business logic and features:** e.g., `auto_wizard.rb`, `bulk_import_info.rb`, `calendar_subscriptions/`,
    `escalation/`, `excel_sheet/`, `external_data_source/`, `knowledge_base/`, `password_policy/`,
    `secure_mailing/`, `stats/`, `tasks/`, etc.
  - **Core extensions:** e.g., `core_ext/` for Ruby or Rails extensions.
  - **Background services and operations:** e.g., `background_services/`, `operations_rate_limiter.rb`,
    `sequencer/`, `transaction_dispatcher.rb`.
  - **Other:** `app_version.rb`, `exceptions.rb`, `models.rb`, `version.rb`, and more.
- Many subfolders contain related modules or classes grouped by feature or integration.

## Runtime, environment, and coding standards

- All runtime and environment constraints are defined in config files. See above for references.
- For setup, troubleshooting, testing, linting, and coding standards, always consult the Developer Manual
  ([`../doc/developer_manual/`](../doc/developer_manual/)).
- For tool versions, scripts, and environment variables, see [`../package.json`](../package.json), [`../Gemfile`](../Gemfile),
  and other config files.
- For path aliases, see [`../tsconfig.base.json`](../tsconfig.base.json).
  For copyright/i18n, see [`../eslint.config.ts`](../eslint.config.ts).

## Legacy desktop-app tips

- Location: [`../app/assets/javascripts`](../app/assets/javascripts) and [`../app/assets/stylesheets`](../app/assets/stylesheets).
- Uses Spine.js for MVC structure. Most modules are Spine classes.
- Uses REST API endpoints (see Rails controllers for routes).
- Linting: [`../coffeelint.json`](../coffeelint.json). Testing: QUnit in [`../test/`](../test/).
- Prefer new work in desktop-view/mobile; keep legacy changes minimal.

## Vue apps tips

- Use path aliases from [`../tsconfig.base.json`](../tsconfig.base.json).
- Do not cross-import between desktop/mobile apps (ESLint enforces boundaries).
- Use Vitest and Testing Library for unit/component tests ([`../app/frontend/tests/`](../app/frontend/tests/)).
- Use Tailwind CSS utilities for styling. Lint with Stylelint and Prettier.
- For i18n, wrap user-facing strings and see [`../eslint.config.ts`](../eslint.config.ts) for rules.

## When in doubt

- The Developer Manual ([`../doc/developer_manual/`](../doc/developer_manual/)) is the source of truth for setup,
  testing, and standards.
- Prefer referencing config files over duplicating information here.
- Keep PRs focused; include tests for new code.
