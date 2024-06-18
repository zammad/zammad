// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { type FormKitNode } from '@formkit/core'

import { FormValidationVisibility } from '#shared/components/Form/types.ts'
import type { AllowedFile } from '#shared/utils/files.ts'

import { useFileValidation } from '../composable/useFileValidation.ts'

const { validateFileSize } = useFileValidation()
export const filesSizeError = (node: FormKitNode) => {
  let commitEventListener: string

  node.on('created', () => {
    node.on('prop:allowedFiles', ({ payload, origin: node }) => {
      if (payload && node.value) {
        const isValid = validateFileSize(node, <FileList>node.value, payload, {
          writeToMsgStore: true,
        })

        if (!isValid) {
          node.emit('prop:validationVisibility', FormValidationVisibility.Live)
        }

        node.on('commit', ({ payload, origin: node }) => {
          if (!node.context?.allowedFiles) return
          const isValid = validateFileSize(
            node,
            payload,
            <AllowedFile[]>node.context.allowedFiles,
            {
              writeToMsgStore: true,
            },
          )
          if (isValid) {
            node.store.remove('fileSizeError')
            node.emit(
              'prop:validationVisibility',
              FormValidationVisibility.Live,
            )
          } else {
            node.emit(
              'prop:validationVisibility',
              FormValidationVisibility.Submit,
            )
          }
        })
      } else if (!payload && commitEventListener) {
        node.store.remove('fileSizeError')
        node.off(commitEventListener)
        node.emit('prop:validationVisibility', FormValidationVisibility.Submit)
      }
    })
  })
}
