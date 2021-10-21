const path = require('path')

module.exports = {
  root: true,
  env: {
    browser: true,
    jest: true,
    node: true,
  },
  plugins: ['@typescript-eslint', 'vue', 'prettier', 'jest'],
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
    'vue/script-setup-uses-vars': 'error',
    'no-console': process.env.NODE_ENV === 'production' ? 'error' : 'off',
    'no-debugger': process.env.NODE_ENV === 'production' ? 'error' : 'off',
    'import/no-extraneous-dependencies': [
      'error',
      { devDependencies: ['vite.config.ts', 'app/frontend/tests/**/*'] },
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
          ['@mobile', path.resolve(__dirname, './app/frontend/apps/mobile')],
          ['@common', path.resolve(__dirname, './app/frontend/common')],
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
