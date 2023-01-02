// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

/**
 * @fileoverview Detect unmarked translatable strings
 * @author Martin Gruner
 */

//------------------------------------------------------------------------------
// Rule Definition
//------------------------------------------------------------------------------

/**
 * @type {import('eslint').Rule.RuleModule}
 */
module.exports = {
  meta: {
    type: 'problem',
    docs: {
      description: 'Detect unmarked translatable strings',
      category: 'Layout & Formatting',
      recommended: true,
      url: null,
    },
    fixable: 'code',
    schema: [],
  },

  create(context) {
    const IGNORE_STRING_PATTERNS = [
      /^[^A-Z]/, // Only look at strings starting with upper case letters
      /\$\{/, // Ignore strings with interpolation
    ]
    const IGNORE_METHODS = ['__']
    const IGNORE_OBJECTS = ['log', 'console', 'i18n']

    return {
      Literal(node) {
        if (typeof node.value !== 'string') {
          return
        }

        const string = node.value

        // Ignore strings with less than two words.
        if (string.split(' ').length < 2) return

        for (const pattern of IGNORE_STRING_PATTERNS) {
          if (string.match(pattern)) return
        }

        // Ignore strings used for comparison
        const tokenBefore = context.getTokenBefore(node)
        if (
          tokenBefore &&
          tokenBefore.type === 'Punctuator' &&
          ['==', '==='].includes(tokenBefore.value)
        ) {
          return
        }

        const { parent } = node

        if (parent.type === 'CallExpression') {
          if (IGNORE_METHODS.includes(parent.callee.name)) return
          if (
            parent.callee.type === 'MemberExpression' &&
            IGNORE_OBJECTS.includes(parent.callee.object.name)
          ) {
            return
          }
        }

        context.report({
          node,
          message:
            'This string looks like it should be marked as translatable via __(...)',
          fix(fixer) {
            return fixer.replaceText(node, `__(${node.raw})`)
          },
        })
      },
    }
  },
}
