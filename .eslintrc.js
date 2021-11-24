// Copyright (C) 2012-2021 Zammad Foundation, https://zammad-foundation.org/

const path = require('path')

module.exports = {
  root: true,
  env: {
    browser: true,
    jest: true,
    node: true,
  },
  plugins: ['@typescript-eslint', 'vue', 'prettier', 'jest', 'zammad'],
  extends: [
    'airbnb-base',
    'plugin:vue/vue3-recommended',
    'plugin:@typescript-eslint/eslint-recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:prettier/recommended',
    'plugin:jest/recommended',
    '@vue/prettier',
    '@vue/typescript/recommended',
    '@vue/prettier/@typescript-eslint',
    'prettier',
  ],
  rules: {
    'zammad/zammad-copyright': 'error',
    'vue/script-setup-uses-vars': 'error',
    'no-console': process.env.NODE_ENV === 'production' ? 'error' : 'off',
    'no-debugger': process.env.NODE_ENV === 'production' ? 'error' : 'off',
    'vue/component-tags-order': [
      'error',
      {
        order: ['template', 'script', 'style'],
      },
    ],
    // Not allow the usage of relative imports, because we want always use the path aliases.
    'no-restricted-imports': [
      'error',
      {
        patterns: [
          {
            group: ['.*'],
            message:
              'Usage of relative imports is not allowed. Always path aliases should be used.',
          },
        ],
      },
    ],
    // Loosen AirBnB's strict rules a bit to allow 'for .. of'
    "no-restricted-syntax": [
      "error",
      "ForInStatement",
      // "ForOfStatement",  // We want to allow this
      "LabeledStatement",
      "WithStatement"
    ],
    // Disable the following rule, because it's not relevant for the tool chain and test envoirment.
    'import/no-extraneous-dependencies': [
      'error',
      {
        devDependencies: [
          'tailwind.config.js',
          'vite.config.ts',
          'app/frontend/tests/**/*',
        ],
      },
    ],
    // Adding typescript file types, because airbnb doesn't allow this by default.
    'import/extensions': [
      'error',
      'ignorePackages',
      {
        js: 'never',
        mjs: 'never',
        jsx: 'never',
        ts: 'never',
        tsx: 'never',
      },
    ],
    /* We strongly recommend that you do not use the no-undef lint rule on TypeScript projects. The checks it provides are already provided by TypeScript without the need for configuration - TypeScript just does this significantly better (Source: https://github.com/typescript-eslint/typescript-eslint/blob/master/docs/getting-started/linting/FAQ.md#i-get-errors-from-the-no-undef-rule-about-global-variables-not-being-defined-even-though-there-are-no-typescript-errors). */
    'no-undef': 'off',

    // We need to use the extended 'no-shadow' rule from typescript:
    // https://github.com/typescript-eslint/typescript-eslint/blob/master/packages/eslint-plugin/docs/rules/no-shadow.md
    'no-shadow': 'off',
    '@typescript-eslint/no-shadow': 'off',

    // Expect assertions are mandatory for async tests.
    'jest/prefer-expect-assertions': [
      'error',
      { onlyFunctionsWithAsyncKeyword: true },
    ],

    // Enforce v-bind directive usage in long form.
    'vue/v-bind-style': ['error', 'longform'],

    // Enforce v-on directive usage in long form.
    'vue/v-on-style': ['error', 'longform'],
  },
  overrides: [
    {
      files: ['*.js'],
      rules: {
        '@typescript-eslint/no-var-requires': 'off',
      },
    },
  ],
  settings: {
    'import/resolver': {
      alias: {
        map: [
          ['@', path.resolve(__dirname, './app/frontend/')],
          ['@mobile', path.resolve(__dirname, './app/frontend/apps/mobile')],
          ['@common', path.resolve(__dirname, './app/frontend/common')],
          ['@tests', path.resolve(__dirname, './app/frontend/tests')],
        ],
        extensions: ['.js', '.jsx', '.ts', '.tsx', '.vue'],
      },
      node: {
        extensions: ['.js', '.jsx', '.ts', '.tsx', '.vue'],
      },
    },
    // Adding typescript file types, because airbnb doesn't allow this by default.
    'import/extensions': ['.js', '.jsx', '.ts', '.tsx', '.vue'],
  },
  globals: {
    defineProps: 'readonly',
    defineEmits: 'readonly',
    defineExpose: 'readonly',
    withDefaults: 'readonly',
  },
  parser: 'vue-eslint-parser',
  parserOptions: {
    parser: '@typescript-eslint/parser', // the typescript-parser for eslint, instead of tslint
    sourceType: 'module', // allow the use of imports statements
    ecmaVersion: 2020, // allow the parsing of modern ecmascript
  },
}
