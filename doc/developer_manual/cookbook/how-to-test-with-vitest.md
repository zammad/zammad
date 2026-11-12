# How to Test With Vitest

We assume you are using our recommended [Devcontainer Setup](../development_environment/devcontainer-setup.md)
and are starting from `develop` branch.

Switching between running tests and doing development work (by running `dev` from `/bin`)
should be effortless without any issues.

The frontend tests are implemented in Vitest, which runs them as three projects (see `vitest.config.mjs`):

- **Unit tests** (`*.spec.ts`) run in jsdom. For the Vue.js 3 component tests we use the "Testing Library", which is
  an offset of the Vue test utils suite. As an addition to the normal unit tests and component tests, we have a suite
  for frontend integration tests.
- **Build tooling tests** (`*.spec.ts` under `app/frontend/build/`) cover the Vite and code generator plugins and run
  in plain Node. `pnpm test` runs them together with the unit tests.
- **Browser tests** (`*.browser.spec.ts`) run in a real Chromium through Vitest browser mode and Playwright. We use
  them where jsdom is not enough, for example for the editor, layout and visual regression screenshots.

## Running

### Unit Tests

The tests will be executed in watch mode by default.

- Run a single test: `pnpm test CommonLink.spec.ts`
- Run a single test case from one test file: `pnpm test FieldSelect.spec.ts -t "supports keyboard navigation"`

> [!WARNING]
>
> Next command should only be run in a CI environment,
> because it consumes a lot of resources.
>
> - Run all tests: `pnpm test`

Check the Vitest [CLI documentation](https://vitest.dev/guide/cli.html#options) for more possibilities.

### Browser Tests

The browser always runs in a Playwright server container, also on your machine, so that the screenshots look the same
for everyone and in CI. Start the server once and leave it running (it needs `docker`):

- `pnpm playwright:server`

The `with-playwright` devcontainer already provides this server. `PLAYWRIGHT_SERVER_URL` points the tests to another
one (default: `ws://localhost:4444/`).

Then run the browser tests like the unit tests:

- Run a single test file: `pnpm test:browser --run editor-basic.browser.spec.ts`
- Run all browser tests: `pnpm test:browser --run`

To check whether a flaky browser test is stable, loop it in CI, see
[How to run filtered CI pipelines](how-to-run-filtered-ci-pipelines.md#loop-a-browser-test).

#### Screenshots

Visual regression tests take a screenshot of an element with `toMatchScreenshot()` and compare it with the reference
screenshot in the `__screenshots__` directory next to the test file. If they differ, the test fails, and the actual
and the diff image end up in `app/frontend/.vitest/attachments`. In CI, the `frontend:vitest:browser` job keeps them
as artifacts.

A missing reference screenshot is recorded, and the test fails once. To record changed screenshots again, add
`--update`, for example `pnpm test:browser --run input-visuals.browser.spec.ts --update`. Review the new images and
commit them together with the change.

## Tooling

- [Vitest - Vite-native unit test framework](https://vitest.dev/) and its
  [browser mode](https://vitest.dev/guide/browser/)
- [Testing suite utils for Vue.js 3](https://test-utils.vuejs.org/) and [Testing Library family](https://testing-library.com/docs/vue-testing-library/intro/)
- [Playwright](https://playwright.dev/), which drives the browser of the browser tests
