# Testing

## Strategy

- Test at the **lowest level** possible — unit over request over E2E
- Focus on the object under test, mock dependencies where it makes sense
- Only important user stories get E2E/system tests (Capybara + Playwright)
- Service specs cover behavior, GraphQL specs only the GraphQL layer —
  see `.dev/agent_docs/testing_services_and_graphql.md`

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

### HTTP streams

- WebMock hands `Net::HTTP` a stubbed response — and a real one it lets through to
  localhost — as one part. A spec that checks that parts arrive one by one switches
  WebMock off for its examples and runs against a plain Rack app on a Puma of its
  own, or a `TCPServer` for what Rack cannot send (headers that trickle in, a TLS
  handshake that never answers).
- The Rails application's middleware holds a streamed response back, so a test
  route in the application does not stream.
- Test a stream parser by feeding the same body whole, in small parts and byte by
  byte, with multi-byte characters and CRLF and CR line ends.

### RSpec meta attributes

- `authenticated_as:` — accepts `true` (admin), `false` (skip login),
  a User, Symbol, or lambda
- `performs_jobs: true` — required to run ActiveJob jobs
  outside of `spec/jobs/`
- `db_strategy: :reset` — reset database after examples that modify
  the schema

### System tests (Capybara + Playwright)

Specs run in Chromium; `TEST_BROWSER=firefox` switches to Firefox.

When Playwright launches the browser locally (`PLAYWRIGHT_SERVER_URL` is
not set), set `TEST_BROWSER_HEADLESS=1` — otherwise it opens a real, visible
browser window — and run a one-time `pnpm playwright:install` per checkout to
download Chromium. A remote browser server (CI, the `with-playwright`
devcontainer) is always headless and needs neither.

```bash
TEST_BROWSER_HEADLESS=1 RAILS_ENV=test VITE_TEST_MODE=1 bundle exec rspec spec/system/path/to/file_spec.rb
```

### Stale legacy assets

System specs for the legacy (CoffeeScript) app run against the compiled
bundle in `public/assets/`. A stale bundle does not fail loudly: a route added
since the last build is missing, Capybara lands on a default page, and the
examples fail with generic errors such as `Unable to find css "tr"`, which
read like a broken selector or a code bug.

Before debugging such a failure, check whether the bundle is older than the
change (`ls -lt public/assets/application-*.js | head -1`, or grep it for a new
symbol), and rebuild it:

```bash
RAILS_ENV=test VITE_TEST_MODE=1 bundle exec rake assets:precompile
```

"Frontend files have changed" in the `CI_SKIP_ASSETS_PRECOMPILE` note above
includes changes that arrived with a pull or rebase, not only your own.

### Ports of a test run

The suite serves Capybara on `CAPYBARA_PORT` (default `3001`) and its websocket
server on `WS_PORT` (default `6043`) — next to, never on, the ports of the
development stack, so a run does not collide with a stack of the same checkout.
Set both to run two suites side by side; they still share the `test` database,
the Redis keys and the Elasticsearch indices, so those (`DATABASE_URL`,
`REDIS_URL`, `ES_INDEX`) need separating as well.

```bash
CAPYBARA_PORT=3101 WS_PORT=6143 bundle exec rspec spec/system/path/to/file_spec.rb
```

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
pnpm test --run app/frontend/path/to/file.spec.ts
```

Always pass `--run` and at least one file path. In an interactive terminal,
watch mode is the default and does not exit. Never put `--` between `pnpm test` and the arguments: pnpm
forwards it, Vitest then ignores everything after it and runs the complete
suite. `VITE_TEST_MODE` is not needed, Vitest enables the test mode itself.

Tests use **Testing Library** (on top of Vue Test Utils).

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
