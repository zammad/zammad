// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/
import {
  evaluateFiles,
  getTranslatableFileTypeName,
  mapValidationTypesAndSizes,
  humanFileSize,
} from '#shared/utils/files.ts'
import { i18n } from '#shared/i18n.ts'
import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import type { FormKitValidationRule } from '@formkit/validation'

interface ParsedRule extends Partial<FormKitValidationRule> {
  name: string
  [key: string]: unknown
}

// TODO: we shouold not use notify and instead impelement a warning message errors or normal text messages.
// TODO: Try to use rules directly instead of utils (e.g. with this also messages should be add one place and not twice).
// TODO: Improve error messages.

export default () => {
  const { notify } = useNotifications()

  const validate = (files: FileList, parsedRules: ParsedRule[]) => {
    const validationRuleSize = parsedRules?.find(
      (rule: { name: string }) => rule.name === 'file_sizes',
    )
    const validationRuleType = parsedRules?.find(
      (rule: { name: string }) => rule.name === 'file_types',
    )
    if (files && validationRuleType) {
      const rules = mapValidationTypesAndSizes(
        validationRuleType.args as string[],
      )

      const { errors, failedFiles } = evaluateFiles(files, rules, {
        validationType: 'mimetype',
      })

      if (errors.type) {
        failedFiles.forEach(({ file }) => {
          const fileType = getTranslatableFileTypeName(file.type, true)
          notify({
            type: NotificationTypes.Error,
            durationMS: 5000,
            message: i18n.t('Type %s is not supported.', i18n.t(fileType)),
          })
        })
        return false
      }
    }
    if (files && validationRuleSize) {
      const rules = mapValidationTypesAndSizes(
        validationRuleSize.args as string[],
      )
      const { errors, failedFiles } = evaluateFiles(files, rules, {
        validationType: 'size',
      })

      if (errors.size) {
        failedFiles.forEach(({ maxSize, file }) => {
          const fileType = getTranslatableFileTypeName(file.type)
          notify({
            type: NotificationTypes.Error,
            durationMS: 5000,
            message: i18n.t(
              'File is too big. %s file has to be %s or smaller.',
              fileType,
              humanFileSize(maxSize as number),
            ),
          })
        })
        return false
      }
    }
    return true
  }

  return {
    validate,
  }
}
