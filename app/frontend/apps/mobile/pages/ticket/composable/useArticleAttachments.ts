// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { useApplicationStore } from '@shared/stores/application'
import { canDownloadFile } from '@shared/utils/files'
import type { ComputedRef } from 'vue'
import { computed } from 'vue'
import type { TicketArticleAttachment } from '@shared/entities/ticket/types'

interface AttachmentsOptions {
  ticketInternalId: number
  articleInternalId: number
  attachments: ComputedRef<TicketArticleAttachment[]>
}

export const useArticleAttachments = (options: AttachmentsOptions) => {
  const application = useApplicationStore()
  const buildBaseUrl = (attachment: TicketArticleAttachment) => {
    const { ticketInternalId, articleInternalId } = options
    const apiUrl = application.config.api_path as string
    return `${apiUrl}/ticket_attachment/${ticketInternalId}/${articleInternalId}/${attachment.internalId}`
  }
  const buildPreviewUrl = (baseUrl: string) => `${baseUrl}?view=preview`
  const canDownloadAttachment = (attachment: TicketArticleAttachment) => {
    return canDownloadFile(attachment.type)
  }
  const buildDownloadUrl = (baseUrl: string, canDownload: boolean) => {
    const dispositionParams = canDownload ? '?disposition=attachment' : ''
    return `${baseUrl}${dispositionParams}`
  }

  const attachments = computed(() => {
    return options.attachments.value.map((attachment) => {
      const baseUrl = buildBaseUrl(attachment)
      const previewUrl = buildPreviewUrl(baseUrl)
      const canDownload = canDownloadAttachment(attachment)
      const downloadUrl = buildDownloadUrl(baseUrl, canDownload)

      return {
        ...attachment,
        previewUrl,
        canDownload,
        downloadUrl,
      }
    })
  })

  return {
    attachments,
  }
}
