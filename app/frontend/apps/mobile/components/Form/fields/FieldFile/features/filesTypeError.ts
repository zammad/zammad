// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { createMessage, type FormKitNode } from '@formkit/core'

import type { FileUploaded } from '#shared/components/Form/fields/FieldFile/types.ts'
import { FormValidationVisibility } from '#shared/components/Form/types.ts'
import { i18n } from '#shared/i18n.ts'

const validateForErrors = (node: FormKitNode, files: FileUploaded[]) => {
  const accept = node.context?.accept as string
  const notAllowedFiles = files.filter(
    (file) => file.type && !accept.includes(file.type),
  )

  if (notAllowedFiles.length === 0) return true

  node.store.set(
    createMessage({
      key: 'filesTypesError',
      blocking: true,
      value: i18n.t(
        'The file type %s is not allowed.',
        notAllowedFiles[0].type,
      ),
      type: 'validation',
      visible: true,
    }),
  )

  return false
}

export const filesTypeError = (node: FormKitNode) => {
  let commitEventListener: string

  node.on('created', () => {
    node.on('prop:accept', ({ payload, origin: node }) => {
      if (payload && node.value) {
        const isValid = validateForErrors(node, node.value as FileUploaded[])

        if (!isValid)
          node.emit('prop:validationVisibility', FormValidationVisibility.Live)

        commitEventListener = node.on('commit', ({ payload, origin: node }) => {
          const isValid = validateForErrors(node, payload)
          if (isValid) {
            node.store.remove('filesTypesError')
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
        node.store.remove('filesTypesError')
        node.off(commitEventListener)
        node.emit('prop:validationVisibility', FormValidationVisibility.Submit)
      }
    })
  })
}
