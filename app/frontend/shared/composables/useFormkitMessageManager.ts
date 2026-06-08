// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { createMessage, getNode } from '@formkit/core'

export const useFormkitMessageManager = (nodeId: string) => {
  const node = getNode(nodeId)

  const setNodeMessage = (
    messageKey: string,
    options: {
      type: 'warning' | 'error'
      message: string
    },
  ) => {
    if (!node) return

    const { type = 'error', message } = options

    node?.store.set(
      createMessage({
        key: messageKey,
        type: type,
        value: message,
        visible: true,
        blocking: false,
      }),
    )
  }

  const removeNodeMessage = (messageKey: string) => {
    if (!node) return

    node.store.remove(messageKey)
  }

  return { setNodeMessage, removeNodeMessage }
}
