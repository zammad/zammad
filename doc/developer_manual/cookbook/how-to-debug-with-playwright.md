# How to Debug System Tests with Playwright

Zammad's browser tests run through Capybara, normally against Selenium. In addition to that there is a **Playwright
driver**, registered next to the Selenium ones. It is currently a pilot: CI runs it as a non-gating shadow lane, and
locally it is mainly a debugging tool, because it records a **trace** of every example - a step-by-step timeline with
screenshots, console output and network requests.

If you are looking for how to write or run browser tests in general, see
[How to test with RSpec / Capybara](how-to-test-with-rspec-and-capybara.md). This page only covers the Playwright
specifics.

## One-Time Setup

The `playwright` npm package comes with `pnpm install`, but it ships no browsers. Download Chromium once per checkout:

```sh
pnpm playwright:install
```

Without it, the first driver call fails with `Executable doesn't exist ... chrome-headless-shell`.

### In the Devcontainer

There is no Playwright service container - the browser is launched inside the devcontainer itself, so the download
above is needed there as well. The devcontainer image does not ship Chromium's shared libraries, and `playwright
install` refuses to continue without them:

```text
Host system is missing dependencies to run browsers.
Please install them with the following command:

    npx playwright install-deps
```

Install them once, then download the browser:

```sh
sudo "$(pnpm bin)/playwright" install-deps chromium
pnpm playwright:install
```

Both are lost on a container rebuild and have to be repeated.

Note that `SELENIUM_REMOTE_URL` has no effect on the Playwright driver - it only knows `PLAYWRIGHT_SERVER_URL`, which
is set in CI only. The Selenium service containers of the `with-selenium` stack are therefore not involved.

## Running a Spec with Playwright

The driver is selected with the same variable as the Selenium browsers:

```sh
SELENIUM_BROWSER=playwright bundle exec rspec spec/system/ticket/zoom_spec.rb
```

The browser is shown by default. Set `SELENIUM_BROWSER_HEADLESS=1` to hide it:

```sh
SELENIUM_BROWSER_HEADLESS=1 SELENIUM_BROWSER=playwright bundle exec rspec spec/system/ticket/zoom_spec.rb
```

In the devcontainer there is no display to show the browser on, so the variable is required there. The `with-selenium`
stack already sets it for the whole container; the default stack does not.

Only Chromium is available. Examples tagged with `mobile_user_agent` automatically use the mobile variant of the driver.

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
PLAYWRIGHT_TRACE=full SELENIUM_BROWSER=playwright bundle exec rspec spec/system/ticket/zoom_spec.rb
```

### Limitations

- Only the default Capybara session is traced. Additional sessions opened via `using_session` run in their own browser
  context and do not appear in the trace.
- The trace file is named after the example, so a retried example (see `rspec-retry`) leaves only the trace of its last
  attempt.

## Traces in CI

The `capybara:playwright` lane runs in every pipeline alongside `capybara:chrome`. It never gates the pipeline, so a red
Playwright lane does not block a merge request.

Its traces are part of the job artifacts (kept on failure, for one week), next to the screenshots and logs. Download the
artifacts of the failed job and open the `.zip` from `tmp/playwright-traces/` as described above.

CI does not use the local browsers - it talks to the `zammad-playwright` service container via `PLAYWRIGHT_SERVER_URL`.

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
| `spec/support/capybara/playwright_driver.rb` | Driver registration, browser and context options, version check |
| `spec/support/capybara/playwright_traces.rb` | Trace recording and the keep-on-failure logic |
| `spec/support/capybara/playwright_driver_patches.rb` | Compensations for gaps in `capybara-playwright-driver` |

The patches are written against one exact version of `capybara-playwright-driver` and refuse to load against another
one. When the gem is updated, check which patches became obsolete upstream before adjusting the pin.
