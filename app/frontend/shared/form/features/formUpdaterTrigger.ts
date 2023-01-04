// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'
import type { FormUpdaterTrigger } from '../../types/form'

const formUpdaterTrigger = (
  defaultTrigger: FormUpdaterTrigger = 'direct',
  defaultTriggerDelay = 300,
) => {
  return (node: FormKitNode) => {
    const { props } = node

    node.addProps(['triggerFormUpdater', 'formUpdaterTrigger'])

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
    })
  }
}

export default formUpdaterTrigger
