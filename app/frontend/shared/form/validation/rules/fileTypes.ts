// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import {
  evaluateFiles,
  getTranslatableFileTypeName,
  mapValidationTypesAndSizes,
} from '#shared/utils/files.ts'
import type { FormKitNode } from '@formkit/core'
import { i18n } from '#shared/i18n/index.ts'

export default {
  ruleType: 'file_types',
  rule: (node: FormKitNode<FileList>, ...args: string[]) => {
    if (!Array.isArray(node.value)) return true
    const rules = mapValidationTypesAndSizes(args)
    const { errors: isValid } = evaluateFiles(node.value, rules, {
      validationType: 'mimetype',
    })
    return !isValid.type
  },
  localeMessage: ({
    node,
    args,
  }: {
    node: FormKitNode<FileList>
    args: string[]
  }) => {
    const rules = mapValidationTypesAndSizes(args)
    const { failedFiles } = evaluateFiles(node.value, rules, {
      validationType: 'mimetype',
    })
    const failedTypes: string[] = []

    failedFiles.forEach((file) => {
      if (file.allowedTypes.length) {
        const fileType = getTranslatableFileTypeName(file.file.type, true)
        failedTypes.push(i18n.t(fileType))
      }
    })
    const failedTypesLocal = failedTypes.join(', ')
    return i18n.t(
      `${failedTypes.length > 1 ? 'Types' : 'Type'} %s ${failedTypes.length > 1 ? 'are' : 'is'} not supported.`,
      failedTypesLocal,
    )
  },
}
