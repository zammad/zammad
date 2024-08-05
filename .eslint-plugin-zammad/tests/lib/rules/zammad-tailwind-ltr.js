// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

/**
 * @fileoverview Enforce "ltr/rtl" rule, if positioning classes are used
 * @author Vladimir Sheremet
 */

//------------------------------------------------------------------------------
// Requirements
//------------------------------------------------------------------------------

/* eslint-disable @typescript-eslint/no-require-imports */
const { RuleTester } = require('eslint')

const rule = require('../../../lib/rules/zammad-tailwind-ltr.js')
/* eslint-enable @typescript-eslint/no-require-imports */

//------------------------------------------------------------------------------
// Tests
//------------------------------------------------------------------------------

const error =
  'When positioning classes are used, they must be prefixed with ltr/rtl.'

const ruleTester = new RuleTester()
ruleTester.run('zammad-tailwind-ltr', rule, {
  valid: [
    {
      filename: 'test.ts',
      code: `console.log('i am testing')`,
    },
    {
      filename: 'test.ts',
      code: `'ltr:pl-2 rtl:pr-2'`,
    },
    {
      filename: 'test.ts',
      code: `'text-black flex flex-col'`,
    },
    {
      filename: 'test.ts',
      code: `{ name: 'ltr:pl-2 rtl:pr-2' }`,
    },
    {
      filename: 'test.js',
      code: `'pl-2 pr-2'`,
    },
    {
      filename: 'test.js',
      code: `{ name: 'pl-2 pr-2' }`,
    },
    {
      filename: 'test.js',
      code: `{ name: 'left-0 right-0' }`,
    },
    {
      filename: 'test.js',
      code: `'left-0 right-0'`,
    },
  ],
  invalid: [
    {
      filename: 'test.js',
      code: `'pl-2'`,
      output: `'rtl:pr-2 ltr:pl-2'`,
      errors: [{ message: error }],
    },
    {
      filename: 'test.js',
      code: `'!pl-2'`,
      output: `'rtl:!pr-2 ltr:!pl-2'`,
      errors: [{ message: error }],
    },
    {
      filename: 'test.js',
      code: `'-pl-2'`,
      output: `'rtl:-pr-2 ltr:-pl-2'`,
      errors: [{ message: error }],
    },
    {
      filename: 'test.js',
      code: `'!-pl-2'`,
      output: `'rtl:!-pr-2 ltr:!-pl-2'`,
      errors: [{ message: error }],
    },
    {
      filename: 'test.js',
      code: `'left-2'`,
      output: `'rtl:right-2 ltr:left-2'`,
      errors: [{ message: error }],
    },
    {
      filename: 'test.js',
      code: `'!left-2'`,
      output: `'rtl:!right-2 ltr:!left-2'`,
      errors: [{ message: error }],
    },
    {
      filename: 'test.js',
      code: `{ name: 'pl-2' }`,
      output: `{ name: 'rtl:pr-2 ltr:pl-2' }`,
      errors: [{ message: error }],
    },
    {
      filename: 'test.js',
      code: `'pr-2'`,
      output: `'rtl:pl-2 ltr:pr-2'`,
      errors: [{ message: error }],
    },
    {
      filename: 'test.js',
      code: `'right-2'`,
      output: `'rtl:left-2 ltr:right-2'`,
      errors: [{ message: error }],
    },
    {
      filename: 'test.js',
      code: `{ name: 'pr-2' }`,
      output: `{ name: 'rtl:pl-2 ltr:pr-2' }`,
      errors: [{ message: error }],
    },
    {
      filename: 'test.js',
      code: `{ name: 'rtl:pl-2 pr-2' }`,
      output: `{ name: 'rtl:pl-2 ltr:pr-2' }`,
      errors: [{ message: error }],
    },
    {
      filename: 'test.js',
      code: `{ name: 'ml-2 pr-2' }`,
      output: `{ name: 'rtl:mr-2 ltr:ml-2 rtl:pl-2 ltr:pr-2' }`,
      errors: [{ message: error }],
    },
    {
      filename: 'test.js',
      code: `{ name: 'ltr:mr-2' }`,
      output: `{ name: 'ltr:mr-2 rtl:ml-2' }`,
      errors: [{ message: error }],
    },
    {
      filename: 'test.ts',
      code: `{ name: 'rtl:pl-2' }`,
      output: `{ name: 'rtl:pl-2 ltr:pr-2' }`,
      errors: [{ message: error }],
    },
    {
      filename: 'test.ts',
      code: `{ name: 'rtl:left-2' }`,
      output: `{ name: 'rtl:left-2 ltr:right-2' }`,
      errors: [{ message: error }],
    },
    {
      filename: 'test.ts',
      code: `'translate-x-2'`,
      output: `'rtl:-translate-x-2 ltr:translate-x-2'`,
      errors: [{ message: error }],
    },
    {
      filename: 'test.ts',
      code: `'!translate-x-2'`,
      output: `'rtl:!-translate-x-2 ltr:!translate-x-2'`,
      errors: [{ message: error }],
    },
    {
      filename: 'test.ts',
      code: `'-translate-x-2'`,
      output: `'rtl:translate-x-2 ltr:-translate-x-2'`,
      errors: [{ message: error }],
    },
    {
      filename: 'test.ts',
      code: `'!-translate-x-2'`,
      output: `'rtl:!translate-x-2 ltr:!-translate-x-2'`,
      errors: [{ message: error }],
    },
    {
      filename: 'test.js',
      code: `'left-0 right-1'`,
      output: `'rtl:right-0 ltr:left-0 rtl:left-1 ltr:right-1'`,
      errors: [{ message: error }],
    },
  ],
})
