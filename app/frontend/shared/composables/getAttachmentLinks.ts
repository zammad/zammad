// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { canDownloadFile, canPreviewFile } from '#shared/utils/files.ts'

interface Attachment {
  type?: Maybe<string>
  internalId: number
}

export const getAttachmentLinks = (attachment: Attachment, apiPath: string) => {
  const buildBaseUrl = () => {
    const { internalId } = attachment
    return `${apiPath}/attachments/${internalId}`
  }
  const buildPreviewUrl = (baseUrl: string, type?: string | null) => {
    if (canPreviewFile(type)) {
      return `${baseUrl}?preview=1`
    }

    return ''
  }

  const buildInlineUrl = (baseUrl: string) => `${baseUrl}?disposition=inline`

  const canDownloadAttachment = (attachment: { type?: Maybe<string> }) => {
    return canDownloadFile(attachment.type)
  }

  const buildDownloadUrl = (baseUrl: string, canDownload: boolean) => {
    const dispositionParams = canDownload ? '?disposition=attachment' : ''
    return `${baseUrl}${dispositionParams}`
  }

  const baseUrl = buildBaseUrl()
  const previewUrl = buildPreviewUrl(baseUrl, attachment.type)
  const canDownload = canDownloadAttachment(attachment)
  const downloadUrl = buildDownloadUrl(baseUrl, canDownload)
  const inlineUrl = buildInlineUrl(baseUrl)

  return {
    baseUrl,
    inlineUrl,
    previewUrl,
    canDownload,
    downloadUrl,
  }
}
