// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { useApplicationStore } from '@shared/stores/application'
import type { ComputedRef } from 'vue'
import { computed } from 'vue'
import type { TicketArticleAttachment } from '@shared/entities/ticket/types'
import { getArticleAttachmentsLinks } from '@shared/entities/ticket-article/composables/getArticleAttachmentsLinks'

interface AttachmentsOptions {
  ticketInternalId: number
  articleInternalId: number
  attachments: ComputedRef<TicketArticleAttachment[]>
}

export const useArticleAttachments = (options: AttachmentsOptions) => {
  const application = useApplicationStore()

  const attachments = computed(() => {
    return options.attachments.value.map((attachment) => {
      const { previewUrl, canDownload, downloadUrl } =
        getArticleAttachmentsLinks(
          {
            ticketInternalId: options.ticketInternalId,
            articleInternalId: options.articleInternalId,
            internalId: attachment.internalId,
            type: attachment.type,
          },
          application.config,
        )

      return {
        ...attachment,
        preview: previewUrl,
        canDownload,
        downloadUrl,
      }
    })
  })

  return {
    attachments,
  }
}
