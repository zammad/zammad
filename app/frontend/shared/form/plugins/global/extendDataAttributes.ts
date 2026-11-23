// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { isEmpty } from 'lodash-es'

import extendSchemaDefinition from '#shared/form/utils/extendSchemaDefinition.ts'

import type { FormKitNode } from '@formkit/core'

const extendDataAttribues = (node: FormKitNode) => {
  const { props, context } = node

  if (!props.definition || !context) return

  if (node.type !== 'input') return

  // Adds a helper function to check the existing value inside of the context.
  context.fns.hasValue = (value: unknown): boolean => {
    if (typeof value === 'object') return !isEmpty(value)

    return value != null && value !== ''
  }

  context.fns.hasWarningMessage = (messages: Record<string, Record<string, unknown>>): boolean => {
    if (!messages) return false

    return Object.values(messages).some((message) => message.type === 'warning' && message.visible)
  }

  extendSchemaDefinition(node, 'outer', {
    attrs: {
      'data-populated': {
        if: '$fns.hasValue($value)',
        then: 'true',
        else: undefined,
      },
      'data-label-hidden': {
        if: '$labelSrOnly === true',
        then: 'true',
        else: undefined,
      },
      'data-required': {
        if: '$state.required',
        then: 'true',
        else: undefined,
      },
      'data-dirty': {
        if: '$state.dirty',
        then: 'true',
        else: undefined,
      },
      'data-triggers-form-updater': {
        if: '$triggerFormUpdater',
        then: 'true',
        else: undefined,
      },
      'data-message-type': {
        if: '$fns.hasWarningMessage($messages)',
        then: 'warning',
        else: undefined,
      },
      'data-alternative-background': {
        if: '$alternativeBackground === true',
        then: 'true',
        else: undefined,
      },
    },
  })
}

export default extendDataAttribues
