# Testing

## Strategy

- Test at the **lowest level** possible — unit over request over E2E
- Focus on the object under test, mock dependencies where it makes sense
- Only important user stories get E2E/system tests (Playwright; legacy app via Capybara)
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

To prove a flaky system spec stable, loop it in CI with the push option
`-o ci.variable="BROWSER_TEST_FILTER=spec/system/path/to/file_spec.rb"`
(see `doc/developer_manual/cookbook/how-to-run-filtered-ci-pipelines.md`).

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

The suite serves Capybara on `CAPYBARA_PORT` (default `3001`), Playwright specs
on `TEST_APP_PORT` (default `3002`) and the websocket server on `WS_PORT`
(default `6043`) — next to, never on, the ports of the development stack, so a
run does not collide with a stack of the same checkout. Set them to run two
suites side by side; they still share the `test` database,
the Redis keys and the Elasticsearch indices, so those (`DATABASE_URL`,
`REDIS_URL`, `ES_INDEX`) need separating as well.

```bash
CAPYBARA_PORT=3101 TEST_APP_PORT=3102 WS_PORT=6143 bundle exec rspec spec/system/path/to/file_spec.rb
```

### Playwright specs (desktop view and mobile app)

New system specs for the desktop view and the mobile app use
`type: :playwright`: Playwright directly, without Capybara. A spec ported from
Capybara replaces its Capybara version, never keep both.

- Find elements by role and accessible name, form fields by their label —
  `page.get_by_role('button', name: 'Create', exact: true)`. No CSS classes,
  ids or `data-test-id`; a missing accessible name is an app bug.
- Open the app with `open_desktop(route)` or `open_mobile(route)`, a ticket of
  the desktop view with `open_desktop_ticket(ticket)`; another tab
  with `open_tab`, the helpers act on it inside `on_tab(tab) { … }`.
- Another user acts inside `as_user(user) { … }`: a browser of their own,
  signed in through the login form (password `test`), closed afterwards.
- Page areas: `main_content`, `page_navigation`, `main_sidebar`,
  `content_sidebar`, `flyout(title)`, `notification(text)`, `table_rows(caption)`,
  `ticket_article(text)`.
- Forms: `fill_field`, `select_option`, `search_for_option` (autocomplete and
  tree select), `selected_options`, all with `within:`. They wait for the form
  updater themselves — never count form updater calls. `type_in_editor` types
  into a rich text editor, `mention_in_editor` mentions a user. `sign_in` fills the
  login form for `authenticated_as: false`.
- `have_text` is the whole text, `contain_text` a part; negations are
  `not_contain_text` etc. Compare plain Ruby arrays with `eq([])`, Playwright's
  matchers take over `be_empty`.
- Regular expressions anchor with `^`/`$`, not `\A`/`\z`.

Support code: `spec/support/playwright/`. Full reference:
`doc/developer_manual/cookbook/how-to-test-with-playwright.md`

### Capybara form helpers (legacy specs)

System tests still on Capybara use custom helpers to interact
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

### Browser specs (Vitest browser mode)

`*.browser.spec.ts` files run in Chromium through Vitest's Playwright
provider, not in jsdom. `vitest.config.mjs` defines the suites as projects:
`unit` (jsdom) and `build` (plain Node, the specs under `app/frontend/build/`),
both run by `pnpm test`, and `browser` (`pnpm test:browser`). The browser
setup (`tests/browser/setup.ts`) tells the apps apart by the spec's path: a
spec under `apps/desktop/` runs with the desktop app's stylesheet, form, icons
and visuals in a laptop viewport, every other one with the mobile app's. The browser always runs
in a Playwright server container, also locally, so that reference
screenshots (`__screenshots__/`) are the same for everyone:

```bash
pnpm playwright:server                                # once, does not exit
pnpm test:browser --run app/frontend/path/to/file.browser.spec.ts
```

`PLAYWRIGHT_SERVER_URL` points to another server (CI, the `with-playwright`
devcontainer). A missing reference screenshot is created and fails the test;
`--update` records changed ones again. Mount with
`#tests/browser/utils.ts` and find elements through `page` from
`vitest/browser`. Pass `config` and `permissions` to `mountComponent` before
mounting, and answer HTTP requests with a fixture from
`tests/browser/fixtures/` via `routeRequest` (it unroutes after the test), or
fail them with `{ networkError: true }`.
GraphQL operations are automocked as in the unit specs: the generated
`*.mocks.ts` helpers (`mockXQuery`, `waitForXQueryCalls`,
`getXSubscriptionHandler`) work in both projects.

To prove a flaky browser spec stable, loop it in CI with the push option
`-o ci.variable="VITEST_BROWSER_TEST_FILTER=file.browser.spec.ts"`, and
optionally `VITEST_BROWSER_TEST_NAME_PATTERN` for `-t` (see
`doc/developer_manual/cookbook/how-to-run-filtered-ci-pipelines.md`).

### Vitest utils

To handle some vue specific setup we use:

For component test -
`app/frontend/tests/support/components/renderComponent.ts`

For integration test -
`app/frontend/tests/support/components/visitView.ts`
