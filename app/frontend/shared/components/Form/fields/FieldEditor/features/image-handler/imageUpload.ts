// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useFormUploadCacheAddMutation } from '#shared/components/Form/fields/FieldFile/graphql/mutations/uploadCache/add.api.ts'
import type { UploadCacheFileInput } from '#shared/graphql/types.ts'
import { convertToGraphQLId, parseGraphqlId } from '#shared/graphql/utils.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'

const ticketAttachmentPath = /^\/api\/v1\/ticket_attachment\/\d+\/\d+\/(\d+)$/

export const isUploadCacheSrc = (src: string) => src.startsWith('/api/v1/attachments/')

export const getTicketAttachmentStoreId = (src: string) => {
  const url = URL.parse(src, window.location.origin)

  if (url?.origin !== window.location.origin) return undefined

  return url.pathname.match(ticketAttachmentPath)?.at(1)
}

const toUploadCacheSrc = (files: { id: string }[]) =>
  files.map((file) => `/api/v1/attachments/${parseGraphqlId(file.id).id}`)

export const uploadInlineImages = async (
  formId: string,
  files: UploadCacheFileInput[],
  options: { errorShowNotification?: boolean } = {},
) => {
  const addFileMutation = new MutationHandler(useFormUploadCacheAddMutation({}), options)

  const response = await addFileMutation.send({
    formId,
    files: files.map((file) => ({ ...file, inline: true })),
  })

  return toUploadCacheSrc(response?.formUploadCacheAdd?.uploadedFiles || [])
}

export const copyInlineImages = (
  formId: string,
  storeIds: string[],
  options: { errorShowNotification?: boolean } = {},
) =>
  uploadInlineImages(
    formId,
    storeIds.map((id) => ({ attachmentId: convertToGraphQLId('Store', id) })),
    options,
  )
