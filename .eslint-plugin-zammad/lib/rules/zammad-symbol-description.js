// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

/**
 * @fileoverview Enforces consistent kebab-case for Symbol descriptors
 * @author Benjamin Scharf
 */

//------------------------------------------------------------------------------
// Rule Definition
//------------------------------------------------------------------------------

/**
 * @type {import('eslint').Rule.RuleModule}
 */
const kebabCaseRegex = /^[a-z-]+$/

module.exports = {
  meta: {
    type: 'problem',
    docs: {
      description: 'Enforce kebab-case for Symbol description',
      category: 'Stylistic Issues',
      recommended: true,
    },
    schema: [],
  },
  create(context) {
    return {
      // eslint-disable-next-line object-shorthand
      'CallExpression[callee.name="Symbol"]'(node) {
        const descriptor = node.arguments[0]
        if (!descriptor && typeof descriptor.value !== 'string') return

        if (!kebabCaseRegex.test(descriptor.value))
          context.report({
            node: descriptor,
            message: 'Symbol description should be in kebab-case.',
          })
      },
    }
  },
}
