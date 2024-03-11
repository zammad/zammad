// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import type { FormKitNode } from '@formkit/core'

import {
  evaluateFiles,
  getTranslatableFileTypeName,
  humanFileSize,
  mapValidationTypesAndSizes,
} from '#shared/utils/files.ts'
import { i18n } from '#shared/i18n/index.ts'
import type { FormValidationRuleType } from '#shared/types/form.ts'

export default <FormValidationRuleType>{
  ruleType: 'file_sizes',
  rule: (node: FormKitNode<FileList>, ...args: string[]) => {
    if (!Array.isArray(node.value)) return true
    const rules = mapValidationTypesAndSizes(args)
    const { errors: isValid } = evaluateFiles(node.value, rules, {
      validationType: 'size',
    })
    return !isValid.size
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
      validationType: 'size',
    })
    const failedSizeFiles = failedFiles.filter((file) => file.maxSize)
    if (failedSizeFiles.length < 2) {
      const fileType = getTranslatableFileTypeName(failedFiles[0].file.type)
      return i18n.t(
        'File is too big. %s file has to be %s or smaller.',
        i18n.t(fileType),
        humanFileSize(<number>failedFiles[0].maxSize),
      )
    }
    const failedTypes: string[] = []
    failedSizeFiles.forEach((file) => {
      const fileType = getTranslatableFileTypeName(file.file.type, true)
      failedTypes.push(
        `${i18n.t(fileType)} ${humanFileSize(<number>file.maxSize)}`,
      )
    })
    return i18n.t('Files are too big. %s', failedTypes.join(', '))
  },
}
