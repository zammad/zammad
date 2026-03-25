# Testing

## Strategy

- Test at the **lowest level** possible — unit over request over E2E
- Focus on the object under test, mock dependencies where it makes sense
- Only important user stories get E2E/system tests (Capybara + Selenium)

## Backend (RSpec)

Tests live in `spec/` mirroring the `app/` structure.
Factories are in `spec/factories/`.

```bash
RAILS_ENV=test VITE_TEST_MODE=1 bundle exec rspec spec/path/to/file_spec.rb     # Run file
RAILS_ENV=test VITE_TEST_MODE=1 bundle exec rspec spec/path/to/file_spec.rb:42  # Run specific example
```

Add `CI_SKIP_DB_RESET=1` to skip database reset between runs.
Add `CI_SKIP_ASSETS_PRECOMPILE=1` to skip asset compilation —
but omit it when frontend files have changed.

### RSpec meta attributes

- `authenticated_as:` — accepts `true` (admin), `false` (skip login),
  a User, Symbol, or lambda
- `performs_jobs: true` — required to run ActiveJob jobs
  outside of `spec/jobs/`
- `db_strategy: :reset` — reset database after examples that modify
  the schema

### Capybara form helpers (new frontend stack)

System tests for the Vue frontend use custom helpers to interact
with FormKit-based fields:

```ruby
find_input('Title').type('text')
find_select('Owner').select_option('Agent Name')
find_autocomplete('Customer').search_for_option(
  customer.email, label: customer.fullname
)
find_editor('Text').type('content')
find_treeselect('Category').select_option('Parent::Child')
find_datepicker('Date').select_date(Date.tomorrow)
find_toggle('Boolean').toggle_on
```

Use `within_form` for stable multi-field interactions — it automatically
waits for form updater (Core Workflow) responses:

```ruby
within_form(form_updater_gql_number: 2) do
  find_autocomplete('CC').search_for_options([email_1, email_2])
  find_editor('Text').type(body)
end
```

For the new frontend system tests, use `wait_for_gql` to wait for
GraphQL responses and `wait_for_test_flag` to wait for frontend
state changes.

Full reference:
`doc/developer_manual/cookbook/how-to-test-with-rspec-and-capybara.md`

## Frontend (Vitest)

Test files use `.spec.ts` extension and are co-located with source files.

```bash
VITE_TEST_MODE=1 pnpm test -- app/frontend/path/to/file.spec.ts
```

Tests use **Testing Library** (on top of Vue Test Utils).
Watch mode is the default.

### Two levels of frontend tests

- **Component/unit tests** — co-located with source files,
  test individual components or composables in isolation
- **Frontend integration tests** — live in `__tests__/` folders
  inside page directories, render the full view with routing

GraphQL requests are mocked via the auto mocker. Activate it by
importing `#tests/graphql/builders/mocks.ts` or by importing a
`.mocks.ts` file next to a GraphQL operation.

Cypress is only used when pure Node.js testing is not possible
(e.g. the editor). See
`doc/developer_manual/cookbook/how-to-test-with-vitest-and-cypress.md`.

### Vitest utils

To handle some vue specific setup we use:

For component test -
`app/frontend/tests/support/components/renderComponent.ts`

For integration test -
`app/frontend/tests/support/components/visitView.ts`
