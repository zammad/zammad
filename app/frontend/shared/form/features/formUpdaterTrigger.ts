// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormUpdaterTrigger } from '../../types/form.ts'
import type { FormKitNode } from '@formkit/core'

const formUpdaterTrigger = (
  defaultTrigger: FormUpdaterTrigger = 'direct',
  defaultTriggerDelay = 300,
) => {
  return (node: FormKitNode) => {
    const { props } = node

    node.addProps([
      'triggerFormUpdater',
      'formUpdaterTrigger',
      'pendingValueUpdate',
    ])

    node.on('created', () => {
      if (!props.formUpdaterTrigger) {
        props.formUpdaterTrigger = defaultTrigger
      }

      if (
        props.triggerFormUpdater &&
        props.formUpdaterTrigger === 'delayed' &&
        (!props.delay || props.delay < defaultTriggerDelay)
      ) {
        props.delay = defaultTriggerDelay
      }

      const { context } = node

      if (!context) return

      // Reset pending value update prop if needed.
      node.hook.input((payload, next) => {
        if (context.pendingValueUpdate) context.pendingValueUpdate = false

        return next(payload)
      })
    })
  }
}

export default formUpdaterTrigger
