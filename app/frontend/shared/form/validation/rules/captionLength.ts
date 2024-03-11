// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'
import { getTranslatableFileTypeName } from '#shared/utils/files.ts'
import { i18n } from '#shared/i18n/index.ts'

const mapRules = (args: string[]) => {
  if (args.length % 2 !== 0)
    throw new Error(__('Invalid arguments for caption validation'))
  const validations: Record<string, number> = {}
  args.forEach((arg, index) => {
    if (index % 2 === 0) {
      validations[arg] = +args[index + 1]
    }
  })
  return validations
}

const getFailedCaption = (
  args: string[],
  bodyLength: number,
  attachments: File[] = [],
) => {
  const validations = mapRules(args)
  return Object.entries(validations).find(([type, wordCount]) => {
    const file = attachments.find((file: File) => file.type?.includes(type))
    return file?.type.includes(type) && wordCount < bodyLength
  })
}
export default {
  ruleType: 'caption_length',
  rule: (node: FormKitNode<string>, ...args: string[]) => {
    /**
     * Works if attachment node is in the same form group
     * 1 Level up in form tree
     * */
    const values = node.parent?.value as {
      attachments: File[]
      [key: string]: unknown
    }
    const attachments = values?.attachments || []
    const bodyText = node.value
    if (!values) return true // if no attachments are present
    let isValid = true
    const validationArgs = mapRules(args)
    // Validate captions based on body length and attachments in a FORM GROUP || FORM
    Object.entries(validationArgs).forEach(([generalType, wordCount]) => {
      if (attachments.length > 0) {
        attachments.forEach((file: File) => {
          if (file.type.includes(generalType)) {
            isValid = bodyText.length <= wordCount
          }
        })
      }
    })
    return isValid
  },
  localeMessage: ({
    node,
    args,
  }: {
    node: FormKitNode<string>
    args: string[]
  }) => {
    const values = node.parent?.value as
      | {
          attachments?: File[]
          [key: string]: unknown
        }
      | undefined
    const failedCaption = getFailedCaption(
      args,
      node.value.length,
      values?.attachments,
    )
    if (!failedCaption) return ''
    const [type, charCount] = failedCaption
    const name = getTranslatableFileTypeName(type)
    if (charCount === 0) {
      return i18n.t('Caption for %s is not allowed. Please clear text!', name)
    }
    return i18n.t(
      'Caption for %s length is too long. Maximum allowed characters are %s',
      name,
      charCount,
    )
  },
}
