// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import type { ConfigList } from '@shared/types/store'
import { canDownloadFile } from '@shared/utils/files'

interface Attachment {
  type?: Maybe<string>
  internalId: number
  articleInternalId: number
  ticketInternalId: number
}

export const getArticleAttachmentsLinks = (
  attachment: Attachment,
  config: ConfigList,
) => {
  const buildBaseUrl = () => {
    const { ticketInternalId, articleInternalId, internalId } = attachment
    const apiUrl = config.api_path as string
    return `${apiUrl}/ticket_attachment/${ticketInternalId}/${articleInternalId}/${internalId}`
  }
  const buildPreviewUrl = (baseUrl: string) => `${baseUrl}?view=preview`
  const canDownloadAttachment = (attachment: { type?: Maybe<string> }) => {
    return canDownloadFile(attachment.type)
  }
  const buildDownloadUrl = (baseUrl: string, canDownload: boolean) => {
    const dispositionParams = canDownload ? '?disposition=attachment' : ''
    return `${baseUrl}${dispositionParams}`
  }

  const baseUrl = buildBaseUrl()
  const previewUrl = buildPreviewUrl(baseUrl)
  const canDownload = canDownloadAttachment(attachment)
  const downloadUrl = buildDownloadUrl(baseUrl, canDownload)

  return {
    baseUrl,
    previewUrl,
    canDownload,
    downloadUrl,
  }
}
