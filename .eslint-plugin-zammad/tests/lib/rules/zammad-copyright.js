// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

/**
 * @fileoverview Enforce presence of Zammad copyright header
 * @author Martin Gruner
 */

//------------------------------------------------------------------------------
// Requirements
//------------------------------------------------------------------------------

const { RuleTester } = require('eslint')

const rule = require('../../../lib/rules/zammad-copyright.js')

//------------------------------------------------------------------------------
// Tests
//------------------------------------------------------------------------------

// NOTE: Cannot test with xml tags inside vue files, as the preprocessors are not running.
const year = new Date().getFullYear()

const ruleTester = new RuleTester({
  languageOptions: {
    parser: require('vue-eslint-parser'), // required to parse .vue files properly otherwise js-parser will be used
  },
})

ruleTester.run('zammad-copyright', rule, {
  valid: [
    {
      filename: 'test.ts',
      code: `// Copyright (C) 2012-${year} Zammad Foundation, https://zammad-foundation.org/`,
    },
    {
      filename: 'test.js',
      code: `// Copyright (C) 2012-${year} Zammad Foundation, https://zammad-foundation.org/`,
    },
    {
      filename: 'test.vue',
      code: `<!-- Copyright (C) 2012-${year} Zammad Foundation, https://zammad-foundation.org/ -->`,
    },
    // Empty file, no change.
    {
      filename: 'test.js',
      code: '',
    },
  ],

  invalid: [
    {
      filename: 'test.js',
      code: 'function foo(){}',
      errors: [{ message: 'Missing Zammad copyright header.' }],
      output: `// Copyright (C) 2012-${year} Zammad Foundation, https://zammad-foundation.org/\n\nfunction foo(){}`,
    },
    {
      filename: 'test.js',
      code: '// Copyright some other value\n\n\nfunction foo(){}',
      errors: [{ message: 'Wrong Zammad copyright header.' }],
      output: `// Copyright (C) 2012-${year} Zammad Foundation, https://zammad-foundation.org/\n\n\nfunction foo(){}`,
    },
    {
      filename: 'test.js',
      code: `// Copyright (C) 2012-${
        year - 1
      } Zammad Foundation, https://zammad-foundation.org/\n\n\nfunction foo(){}`,
      errors: [{ message: 'Wrong Zammad copyright header.' }],
      output: `// Copyright (C) 2012-${year} Zammad Foundation, https://zammad-foundation.org/\n\n\nfunction foo(){}`,
    },
    {
      filename: 'test.vue',
      code: 'function foo(){}',
      errors: [{ message: 'Missing Zammad copyright header.' }],
      output: `<!-- Copyright (C) 2012-${year} Zammad Foundation, https://zammad-foundation.org/ -->\n\nfunction foo(){}`,
    },
    {
      filename: 'test.vue',
      code: '<!-- Copyright some other value -->\n\n\n',
      errors: [{ message: 'Wrong Zammad copyright header.' }],
      output: `<!-- Copyright (C) 2012-${year} Zammad Foundation, https://zammad-foundation.org/ -->\n\n\n`,
    },
  ],
})
