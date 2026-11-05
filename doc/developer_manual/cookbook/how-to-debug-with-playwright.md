# How to Debug System Tests with Playwright

Zammad's browser tests run through Capybara on the **Playwright driver**. Besides driving the browser, it records a
**trace** of every example - a step-by-step timeline with screenshots, console output and network requests - which
makes it a debugging tool as well.

If you are looking for how to write or run browser tests in general, see
[How to test with RSpec / Capybara](how-to-test-with-rspec-and-capybara.md). This page only covers the Playwright
specifics.

## One-Time Setup

The `playwright` npm package comes with `pnpm install`, but it ships no browsers. Download Chromium once per checkout:

```sh
pnpm playwright:install
```

Without it, the first driver call fails with `Executable doesn't exist ... chrome-headless-shell`.

The Firefox driver (`TEST_BROWSER=firefox`) uses Playwright's own Firefox build, which this script does not download.
Install it once as well if you want to use that driver:

```sh
pnpm exec playwright install firefox
```

### In the Devcontainer

The `with-playwright` stack runs a Playwright browser server next to the devcontainer and points the tests at it via
`PLAYWRIGHT_SERVER_URL`, so nothing has to be installed there. Its browsers are always headless, and the stack also comes
with built-in debugging tools, so it's not needed to run the commands above.

However, in the other stacks the browser is launched inside the devcontainer itself, so the download above is needed there
as well. The devcontainer image does not ship Chromium's shared libraries, and `playwright install` refuses to continue
without them:

```text
Host system is missing dependencies to run browsers.
Please install them with the following command:

    npx playwright install-deps
```

Install them once, then download the browser:

```sh
sudo env PATH="$PATH" pnpm playwright install-deps chrome-for-testing
pnpm playwright:install
```

Both are lost on a container rebuild and have to be repeated.

## Choosing the Browser

Specs run in Chromium by default. `TEST_BROWSER=firefox` runs them in Playwright's Firefox build instead (see the
one-time setup above):

```sh
TEST_BROWSER=firefox bundle exec rspec spec/system/ticket/zoom_spec.rb
```

The browser is shown by default. Set `TEST_BROWSER_HEADLESS=1` to hide it:

```sh
TEST_BROWSER_HEADLESS=1 bundle exec rspec spec/system/ticket/zoom_spec.rb
```

When the browser is launched inside a devcontainer, there is no display to show it on, so the variable is required
there. Examples tagged with `mobile_user_agent` automatically use the mobile variant of the driver.

## Traces

A trace is recorded for every example and deleted again when the example passes. **Failed examples keep their trace** in
`tmp/playwright-traces/`, named after the example ID:

```text
tmp/playwright-traces/_spec_system_ticket_zoom_spec_rb_1_7_.zip
```

Open it in the Playwright trace viewer:

```sh
pnpm exec playwright show-trace tmp/playwright-traces/_spec_system_ticket_zoom_spec_rb_1_7_.zip
```

In the devcontainer, `show-trace` has no window to open either. Let it serve the viewer over HTTP instead and open the
forwarded port:

```sh
pnpm exec playwright show-trace --port 9323 tmp/playwright-traces/_spec_system_ticket_zoom_spec_rb_1_7_.zip
```

Alternatively, drop the file on <https://trace.playwright.dev> - the devcontainer workspace is a bind mount, so the
trace files are on the host checkout and can be opened from a browser there. According to
[its documentation](https://playwright.dev/docs/trace-viewer), the viewer "loads the trace entirely in your browser and
does not transmit any data externally".

The trace shows every action the driver performed, a screencast of what the page looked like while it happened, and the
browser console and network requests on the same timeline. That is usually enough to see _when_ a page stopped behaving
as the spec expected, which the single failure screenshot in `tmp/screenshots/` cannot tell you.

### DOM Snapshots

The trace viewer can also travel back in time and let you inspect the live DOM of every step, including the element the
action was performed on. This needs DOM snapshots, which are **off by default**: they are captured per Playwright action
and cost 27-46% of the runtime of a desktop spec. Turn them on for a single run when you need them:

```sh
PLAYWRIGHT_TRACE=full bundle exec rspec spec/system/ticket/zoom_spec.rb
```

### Limitations

- Examples tagged with `required_envs` are not traced, because they work with real credentials.
- Only the default Capybara session is traced. Additional sessions opened via `using_session` run in their own browser
  context and do not appear in the trace.
- The trace file is named after the example, so a retried example (see `rspec-retry`) leaves only the trace of its last
  attempt.

## Traces in CI

The traces of the `capybara:*` lanes are part of the job artifacts (kept on failure, for one week), next to the
screenshots and logs. Download the artifacts of the failed job and open the `.zip` from `tmp/playwright-traces/` as
described above.

CI does not use the local browsers - it talks to the `zammad-playwright` service container via `PLAYWRIGHT_SERVER_URL`.

## Remote Debugging via Chromium DevTools

The devcontainer Playwright stack also provides an out-of-the-box live view of the headless browser via DevTools. Headless
Chromium can stream its screen to Chrome DevTools without any X server. The debugging port is automatically forwarded at
`9222` to the host. On your host open `chrome://inspect`, add `localhost:9222` under "Configure...", and click "inspect"
on the page. You get a live screencast and can interact with it. Pause the spec with `binding.pry` or a `sleep` to look
around. The devcontainer sets `PLAYWRIGHT_REMOTE_DEBUGGING_PORT=9222` for this; set it yourself to get the same outside
of it.

Chromium binds that port on `127.0.0.1` and, once that is taken, on `::1` if IPv6 is available. When neither is free, the
launch of the next browser hangs until it times out. Run a single spec file at a time, and unset the variable for specs
that open more browser sessions (`using_session`).

## Version Lockstep

The `playwright` npm package, the `PLAYWRIGHT_VERSION` CI variable and the `playwright-ruby-client` gem have to be on
the same version, otherwise the two protocol sides drift apart silently. This is checked before a browser is started,
and a mismatch fails the run with an explicit message:

```text
playwright version drift: the playwright-ruby-client gem needs 1.62.1, but package.json has "1.61.0" ...
```

Bumping the gem therefore also means bumping `package.json` and the CI variable in
`.gitlab/ci/__includes__/services.yml`.

## Where the Code Lives

| File | Purpose |
| --- | --- |
| `spec/support/playwright/browser.rb` | Browser launch and server connection, launch options, version check |
| `spec/support/capybara/playwright_driver.rb` | Driver registration, context options |
| `spec/support/capybara/playwright_traces.rb` | Trace recording and the keep-on-failure logic |
| `spec/support/capybara/playwright_driver_patches.rb` | Compensations for gaps in `capybara-playwright-driver` |

The patches are written against one exact version of `capybara-playwright-driver` and refuse to load against another
one. When the gem is updated, check which patches became obsolete upstream before adjusting the pin.
