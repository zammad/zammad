// Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

import { isEmpty } from 'lodash-es'
import type { FormKitNode } from '@formkit/core'
import extendSchemaDefinition from '@shared/form/utils/extendSchemaDefinition'

const extendDataAttribues = (node: FormKitNode) => {
  const { props, context } = node

  if (!props.definition || !context || node.type !== 'input') return

  // Adds a helper function to check the existing value inside of the context.
  context.fns.hasValue = (value: unknown): boolean => {
    if (typeof value === 'object') return !isEmpty(value)
    if (typeof value === 'number') return value !== undefined && value !== null

    return !!value
  }

  context.fns.hasRule = (
    rule?: string,
    ruleSet?: string | Array<Array<string>>,
  ) => {
    if (!ruleSet || !rule) return false

    if (Array.isArray(ruleSet)) return ruleSet.some((r) => r.includes(rule))

    return ruleSet
      .split('|')
      .map((r) => r.split(/:|,+/g))
      .some((r) => r.includes(rule))
  }

  extendSchemaDefinition(node, 'outer', {
    attrs: {
      'data-populated': {
        if: '$fns.hasValue($_value)',
        then: 'true',
        else: undefined,
      },
      'data-required': {
        if: '$fns.hasRule("required", $node.props.validation)',
        then: 'true',
        else: undefined,
      },
    },
  })
}

export default extendDataAttribues
