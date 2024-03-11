// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { createMessage, type FormKitNode } from '@formkit/core'

import { i18n } from '#shared/i18n.ts'

export const multipleFilesError = (node: FormKitNode) => {
  node.on('created', () => {
    let commitEventListener: string

    node.on('prop:multiple', ({ payload, origin: node }) => {
      if (!payload && Array.isArray(node.value) && node.value.length > 1) {
        node.store.set(
          createMessage({
            key: 'multipleFilesError',
            blocking: true,
            value: i18n.t('This field allows only one file.'),
            type: 'validation',
            visible: true,
          }),
        )

        // TODO we would need to switch validationVisible to true

        commitEventListener = node.on('commit', ({ payload: newValue }) => {
          if (Array.isArray(newValue) && newValue.length === 1) {
            node.store.remove('multipleFilesError')
          }
        })
      } else if (payload && commitEventListener) {
        node.off(commitEventListener)
        node.store.remove('multipleFilesError')
      }
    })
  })
}
