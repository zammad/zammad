# How to Test With Vitest and Cypress

The frontend tests are implemented in Vitest.
For the Vue.js 3 component tests we use the "Testing Library", which is a offset of the Vue test utils suite.

As an addition to the normal unit tests and component tests, we have a suite for frontend integration tests.

In situations where the testing with pure Node.js is not possible, we are using the cypress component
testing functionality. For example we are using this for testing the editor.

## Running

### Vitest

The tests will be executed in watch mode by default.

- Run a single test: `yarn test CommonLink.spec.ts`
- Run a single test case from one test file: `yarn test FieldSelect.spec.ts -t "supports keyboard navigation"`
- Run all tests: `yarn test`

Check the Vitest [CLI documentation](https://vitest.dev/guide/cli.html#options) for more possibilities.

### Cypress

First, the Cypress dependencies needs to be installed: `yarn cypress:install`.

Then you can run `yarn test:ct`, which opens an UI in the selected browser. Here the different tests
can be executed.

## Tooling

- [Vitest - Vite-native unit test framework](https://vitest.dev/)
- [Testing suite utils for Vue.js 3](https://test-utils.vuejs.org/) and [Testing Library family](https://testing-library.com/docs/vue-testing-library/intro/)
- [Cypress component testing](https://docs.cypress.io/guides/component-testing)
