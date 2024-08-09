// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

/**
 * @fileoverview Enforce kebab-case for Symbol descriptors
 * @author Benjamin Scharf
 */

//------------------------------------------------------------------------------
// Requirements
//------------------------------------------------------------------------------

/* eslint-disable @typescript-eslint/no-require-imports */
const { RuleTester } = require('eslint')

const rule = require('../../../lib/rules/zammad-symbol-description.js')
/* eslint-enable @typescript-eslint/no-require-imports */

//------------------------------------------------------------------------------
// Tests
//------------------------------------------------------------------------------

const ruleTester = new RuleTester({
  parser: require.resolve('vue-eslint-parser'),
  parserOptions: {
    ecmaVersion: 2020,
    sourceType: 'module',
  },
})

ruleTester.run('zammad-symbol-descriptor', rule, {
  valid: [
    {
      filename: 'test.ts',
      code: `Symbol('foo-bar')`,
    },
    {
      filename: 'test.ts',
      code: `Symbol('foo')`,
    },
    {
      filename: 'test.js',
      code: `Symbol('foo')`,
    },
    {
      filename: 'test.js',
      code: `Symbol('foo-bar')`,
    },
    {
      filename: 'test.vue',
      code: `<script lang="ts" setup>Symbol('foo-bar')</script>`,
    },
    {
      filename: 'test.vue',
      code: `<script lang="ts" setup>Symbol('foo')</script>`,
    },
  ],

  invalid: [
    {
      filename: 'test.ts',
      code: `Symbol('FooBar')`,
      errors: [{ message: 'Symbol description should be in kebab-case.' }],
    },
    {
      filename: 'test.ts',
      code: `Symbol('fooBar')`,
      errors: [{ message: 'Symbol description should be in kebab-case.' }],
    },
    {
      filename: 'test.ts',
      code: `Symbol('foo bar')`,
      errors: [{ message: 'Symbol description should be in kebab-case.' }],
    },
    {
      filename: 'test.js',
      code: `Symbol('FooBar')`,
      errors: [{ message: 'Symbol description should be in kebab-case.' }],
    },
    {
      filename: 'test.js',
      code: `Symbol('fooBar')`,
      errors: [{ message: 'Symbol description should be in kebab-case.' }],
    },
    {
      filename: 'test.ts',
      code: `Symbol('foo bar')`,
      errors: [{ message: 'Symbol description should be in kebab-case.' }],
    },
    {
      filename: 'test.vue',
      code: `<script lang="ts" setup> Symbol('FooBar')</script>`,
      errors: [{ message: 'Symbol description should be in kebab-case.' }],
    },
    {
      filename: 'test.vue',
      code: `<script lang="ts" setup> Symbol('fooBar')</script>`,
      errors: [{ message: 'Symbol description should be in kebab-case.' }],
    },
    {
      filename: 'test.vue',
      code: `<script lang="ts" setup> Symbol('foo bar')</script>`,
      errors: [{ message: 'Symbol description should be in kebab-case.' }],
    },
  ],
})
