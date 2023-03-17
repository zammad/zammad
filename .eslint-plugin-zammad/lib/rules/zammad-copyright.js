// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

/**
 * @fileoverview Enforce presence of Zammad copyright header
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
      description: 'Enforce presence of Zammad copyright header',
      category: 'Layout & Formatting',
      recommended: true,
      url: null,
    },
    fixable: 'code',
    schema: [],
  },

  create(context) {
    const year = new Date().getYear() + 1900

    let expectedComment = `// Copyright (C) 2012-${year} Zammad Foundation, https://zammad-foundation.org/`
    let findComment = '// Copyright'
    if (context.getFilename().endsWith('.vue')) {
      expectedComment = `<!-- Copyright (C) 2012-${year} Zammad Foundation, https://zammad-foundation.org/ -->`
      findComment = '<!-- Copyright'
    }

    return {
      Program(node) {
        const firstLine = context.getSourceCode().lines[0]
        if (!firstLine.length) return
        if (firstLine === expectedComment) return
        if (firstLine.startsWith(findComment)) {
          const range = [0, firstLine.length]
          context.report({
            loc: node.loc,
            message: 'Wrong Zammad copyright header.',
            fix(fixer) {
              return fixer.replaceTextRange(range, expectedComment)
            },
          })
          return
        }
        context.report({
          loc: node.loc,
          message: 'Missing Zammad copyright header.',
          fix(fixer) {
            return fixer.insertTextBeforeRange([0, 0], `${expectedComment}\n\n`)
          },
        })
      },
    }
  },
}
