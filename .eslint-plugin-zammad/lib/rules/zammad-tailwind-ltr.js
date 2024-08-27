// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

/**
 * @fileoverview Enforce "ltr/rtl" rule, if positioning classes are used
 * @author Vladimir Sheremet
 */

//------------------------------------------------------------------------------
// Rule Definition
//------------------------------------------------------------------------------

const parsePossibleClassString = (classesList) => {
  const counterparts = {
    left: 'right',
    right: 'left',
    pl: 'pr',
    pr: 'pl',
    ml: 'mr',
    mr: 'ml',
    rtl: 'ltr',
    ltr: 'rtl',
  }

  Object.entries(counterparts).forEach(([key, value]) => {
    counterparts[`-${key}`] = `-${value}`
    counterparts[`!${key}`] = `!${value}`
    counterparts[`!-${key}`] = `!-${value}`
  })

  counterparts['translate-x'] = '-translate-x'
  counterparts['-translate-x'] = 'translate-x'
  counterparts['!translate-x'] = '!-translate-x'
  counterparts['!-translate-x'] = '!translate-x'

  const classes = classesList.split(' ')

  const errors = []

  const baseClass = Object.keys(counterparts).join('|')

  classes.forEach((className) => {
    const match = className.match(new RegExp(`^(${baseClass})-([^\n]+)`))
    if (!match) return
    const [, prefix, value] = match
    const counterpart = `${counterparts[prefix]}-${value}` // pl-2 pr-2 is the same with or without ltr/rtl
    if (classes.includes(counterpart)) return
    errors.push({
      remove: className,
      add: [`rtl:${counterpart}`, `ltr:${className}`],
    })
  })

  classes.forEach((className) => {
    const match = className.match(
      new RegExp(`^(rtl|ltr):(${baseClass})-([^\n]+)`),
    )
    if (!match) return
    const [, dir, prefix, value] = match
    if (value === '0') return
    const counterpart = `${counterparts[dir]}:${counterparts[prefix]}-${value}`
    if (classes.includes(counterpart)) return
    errors.push({
      remove: null,
      add: [counterpart],
    })
  })

  return {
    classes,
    errors,
  }
}

/**
 * @type {import('eslint').Rule.RuleModule}
 */
module.exports = {
  meta: {
    type: 'problem',
    docs: {
      description: 'Enforce "ltr/rtl" rule, if positioning classes are used',
      category: 'Layout & Formatting',
      recommended: true,
      url: null,
    },
    fixable: 'code',
    schema: [],
  },

  create(context) {
    const visitor =
      context.sourceCode.parserServices?.defineTemplateBodyVisitor ||
      ((obj1, obj2) => ({ ...obj1, ...obj2 }))

    const processLiteral = (node, quotes = "'") => {
      const content = node.value

      if (typeof content !== 'string') return

      const { errors, classes } = parsePossibleClassString(content)

      if (errors.length) {
        context.report({
          loc: node.loc,
          message:
            'When positioning classes are used, they must be prefixed with ltr/rtl.',
          fix(fixer) {
            const newClasses = [...classes]
            errors.forEach(({ remove, add }) => {
              if (remove) {
                const index = newClasses.indexOf(remove)
                newClasses.splice(index, 1)
              }
              add.forEach((a) => {
                if (!newClasses.includes(a)) {
                  newClasses.push(a)
                }
              })
            })
            return fixer.replaceText(
              node,
              `${quotes}${newClasses.join(' ')}${quotes}`,
            )
          },
        })
      }
    }

    return visitor(
      {
        VLiteral: (node) => processLiteral(node, '"'),
        Literal: (node) => processLiteral(node, "'"),
      },
      {
        Literal: (node) => processLiteral(node, "'"),
      },
    )
  },
}
