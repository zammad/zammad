// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { useFormUploadCacheAddMutation } from '#shared/components/Form/fields/FieldFile/graphql/mutations/uploadCache/add.api.ts'
import { parseGraphqlId } from '#shared/graphql/utils.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import type { ImageFileData, ImageFileSource } from '#shared/utils/files.ts'

import { useFileUploadProcessing } from '../../composables/useFileUploadProcessing.ts'

export const useImageUpload = (
  formId: string,
  name: string,
  inline: boolean,
) => {
  const addFileMutation = new MutationHandler(useFormUploadCacheAddMutation({}))

  const { setFileUploadProcessing, removeFileUploadProcessing } =
    useFileUploadProcessing(formId, name)

  const uploadImage = (
    files: ImageFileData[],
    successCallback: (files: ImageFileSource[]) => void,
  ) => {
    setFileUploadProcessing()

    return addFileMutation
      .send({
        formId,
        files: files.map((file) => ({
          name: file.name,
          type: file.type,
          content: file.content,
          inline,
        })),
      })
      .then((response) => {
        const uploadedFiles = response?.formUploadCacheAdd?.uploadedFiles.map(
          (file) => {
            return {
              name: file.name,
              type: file.type,
              src: `/api/v1/attachments/${parseGraphqlId(file.id).id}`,
            }
          },
        ) as ImageFileSource[]

        successCallback(uploadedFiles)
      })
      .finally(() => {
        removeFileUploadProcessing()
      })
  }

  return { uploadImage }
}
