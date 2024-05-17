// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { createMessage, type FormKitNode } from '@formkit/core'

import { i18n } from '#shared/i18n.ts'
import {
  type AllowedFile,
  humanizeFileSize,
  validateFileSizes,
} from '#shared/utils/files.ts'

export const useFileValidation = () => {
  const validateFileSize = (
    node: FormKitNode,
    files: FileList | Array<File>,
    allowedFiles: AllowedFile[],
    options = {
      writeToMsgStore: false,
    },
  ) => {
    const fileList = Array.isArray(files) ? files : Array.from(files)
    const failedFiles = validateFileSizes(fileList, allowedFiles)
    if (failedFiles.length === 0) return true
    const failedFile = failedFiles[0]
    const errorMsg = i18n.t(
      'File is too big. %s has to be %s or smaller.',
      failedFile.label,
      humanizeFileSize(failedFile.maxSize),
    )
    if (options.writeToMsgStore) {
      node.store.set(
        createMessage({
          key: 'fileSizeError',
          blocking: true,
          value: errorMsg,
          type: 'validation',
          visible: true,
        }),
      )
    } else {
      node.setErrors(errorMsg)
    }

    return false
  }
  return { validateFileSize }
}
