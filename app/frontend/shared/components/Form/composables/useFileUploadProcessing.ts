// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { createMessage } from '@formkit/core'

import { getNodeByName } from '../utils.ts'

export const useFileUploadProcessing = (formId: string, fieldName: string) => {
  const fieldNode = getNodeByName(formId, fieldName)

  const setFileUploadProcessing = () => {
    fieldNode?.root?.store.set(
      createMessage({
        blocking: true,
        key: 'uploadProcessing',
        value: true,
        visible: false,
      }),
    )
  }

  const removeFileUploadProcessing = () => {
    fieldNode?.root?.store.remove('uploadProcessing')
  }

  return {
    setFileUploadProcessing,
    removeFileUploadProcessing,
  }
}
