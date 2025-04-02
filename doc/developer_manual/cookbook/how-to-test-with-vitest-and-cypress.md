# How to Test With Vitest and Cypress

The frontend tests are implemented in Vitest.
For the Vue.js 3 component tests we use the "Testing Library", which is an offset of the Vue test utils suite.

As an addition to the normal unit tests and component tests, we have a suite for frontend integration tests.

In situations where the testing with pure Node.js is not possible, we are using the cypress component
testing functionality. For example we are using this for testing the editor.

## Running

### Vitest

The tests will be executed in watch mode by default.

- Run a single test: `pnpm test CommonLink.spec.ts`
- Run a single test case from one test file: `pnpm test FieldSelect.spec.ts -t "supports keyboard navigation"`
- Run all tests: `pnpm test`

Check the Vitest [CLI documentation](https://vitest.dev/guide/cli.html#options) for more possibilities.

### Cypress

First, the Cypress dependencies needs to be installed: `pnpm cypress:install`.

Then you can run `pnpm test:ct`, which opens an UI in the selected browser. Here the different tests can be executed.

> NOTE: Do not try to run snapshot tests in your development environment or with Cypress GUI, since the snapshots will
> most likely differ from the ones made in CI (see below).

#### Snapshots

All visual regression tests end with `-visual.cy.ts` in their filename. They work by creating a screenshot of an
element. Usually, all correct screenshots are already stored inside a git repository. Cypress then compares two
screenshots - if they differ, the test will fail.

To run the snapshot tests use `CYPRESS_UPDATE_SNAPSHOTS=false pnpm cypress:snapshots` command. This will run all
snapshot tests inside a Docker container to ensure they are running in the same environment in CI and on local machine.
Before running command, make sure you have `docker` and `docker-compose` installed.

To update snapshots, use `pnpm cypress:snapshots` command. This will run all snapshot tests inside the same inside
docker container, but this time it will update and overwrite stored screenshots (the tests will never fail). All that
is needed afterwards is to stage and commit updated screenshot files.

## Tooling

- [Vitest - Vite-native unit test framework](https://vitest.dev/)
- [Testing suite utils for Vue.js 3](https://test-utils.vuejs.org/) and [Testing Library family](https://testing-library.com/docs/vue-testing-library/intro/)
- [Cypress component testing](https://docs.cypress.io/guides/component-testing)
