// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

/**
 * @fileoverview Detect unmarked translatable strings
 * @author Martin Gruner
 */

//------------------------------------------------------------------------------
// Requirements
//------------------------------------------------------------------------------

const { RuleTester } = require('eslint')
const rule = require('../../../lib/rules/zammad-detect-translatable-string')

//------------------------------------------------------------------------------
// Tests
//------------------------------------------------------------------------------

const ruleTester = new RuleTester()
ruleTester.run('zammad-detect-translatable-string', rule, {
  valid: [
    {
      filename: 'test.ts',
      code: `'OnlyOneWord'`,
    },
    {
      filename: 'test.ts',
      code: `'starts with lower case'`,
    },
    {
      filename: 'test.ts',
      code: `if (variable === 'Some test string') true`,
    },
    {
      filename: 'test.ts',
      code: `__('Already marked message.')`,
    },
    {
      filename: 'test.ts',
      code: `i18n.t('Already translated string.')`,
    },
    {
      filename: 'test.ts',
      code: `console.log('Some debug message.')`,
    },
    {
      filename: 'test.ts',
      // eslint-disable-next-line no-template-curly-in-string
      code: '"String with ${interpolation}..."', // Not fully correct, but a ``-template string does not seem to work.
    },
  ],

  invalid: [
    {
      filename: 'test.js',
      code: `'String that should be translatable'`,
      errors: [
        {
          message:
            'This string looks like it should be marked as translatable via __(...)',
        },
      ],
      output: `__('String that should be translatable')`,
    },
  ],
})
