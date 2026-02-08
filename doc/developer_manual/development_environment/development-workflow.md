# Development Workflow

This guide provides reference for the main tasks, scripts, and commands used when developing Zammad.

## Rake Tasks & Automation

Zammad provides several Rake tasks to streamline development and setup.

### Database Tasks

- `rails db:drop zammad:db:init` – Reset an existing development database (without running `auto_wizard`)
- `rails db:migrate` – Run any pending Rails migrations

### Package Tasks

- `rails zammad:package:migrate` – Run any pending package migrations

### System Setup Tasks

- `rails zammad:setup:auto_wizard` – Setup system from an `auto_wizard` definition

### Search & Indexing

- `rails zammad:searchindex:rebuild` – Full re-creation of all search indexes and re-indexing of all data

### Translation Tasks

- `rails generate zammad:translation_catalog` – Regenerate the translation catalog
- `rails generate zammad:translation_catalog --full` – Update template files from translations
- `rails zammad:translations:sync` – Synchronize latest translations from `i18n/*.po` to the database

## Useful Scripts

Zammad includes scripts to streamline common tasks.

### Legacy Stack

- `(cd public/assets/images && pnpm install --frozen-lockfile && pnpm exec gulp build)` - Regenerate icon assets

### New Stack

- `pnpm generate-graphql-api` - Regenerate GraphQL introspection file
- `pnpm generate-setting-types` - Regenerate Zammad setting types
- `pnpm generate:install` - Setup code generation tools
- `pnpm generate:generic-component` - Generate generic component
- `pnpm generate:composable` - Generate generic composable
- `pnpm generate:store` - Generate generic store

## Testing

Run tests frequently to verify your changes and avoid regressions.

### Setup

Before running tests for the first time, prepare the test database and compile assets:

- [How to test with Rspec and Capybara](../cookbook/how-to-test-with-rspec-and-capybara.md#running)

Further testing:

- [How to test with Vitest and Cypress](../cookbook/how-to-test-with-vitest-and-cypress.md)

## Linting

Linting ensures consistent code style and readability. They are optional but recommended:

- [CoffeeLint](http://www.coffeelint.org/)
- [Stylelint](https://stylelint.io/)
- [ESLint](https://eslint.org/)
- [Markdownlint](https://github.com/DavidAnson/markdownlint)

These tools are included in the devcontainer; for [manual setups](manual-setup.md) you may want to install them
to ensure consistent code style.

## Rails Console & Environment Variables

Some tasks can be executed directly via Rails console or `rails r`:

### Import / Enable Features

- `cat filename.eml | rails r 'Channel::Driver::MailStdin.new'` - Import an email message as a ticket
- `rails r 'Channel.last.update!(active: true)'` - Enable dummy email channel (i.e. from `auto_wizard`)

### Configure System Settings

- `rails r "Setting.set('es_url', 'http://elasticsearch:9200')"` - Configure Elasticsearch host
- `rails r "Setting.set('core_workflow_ajax_mode', true)"` - Enable Core Workflow AJAX mode
- `rails r "Setting.set('ui_desktop_beta_switch', true)"` - Enable Desktop View BETA UI toggle

### Manage Packages

- `rails c 'Package.link(%q!/path/to/package/checkout!)'` - Link a package
- `rails c 'Package.unlink(%q!/path/to/package!)'` - Unlink a package

For further information see:

- [Rails Console Reference](https://next.zammad.org/en/reference/console.html)
- [Environment Variables](https://next.zammad.org/en/reference/environment-variables.html)

## Further Reading

Learn more about developing and contributing to Zammad:

- [Cookbooks](../cookbook/) - Step-by-step guides for specific tasks
- [Contributing](https://next.zammad.org/en/contribute/contribute.html) – How to contribute code to Zammad
