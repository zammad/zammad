// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import type { TicketArticleAttachment } from '#shared/entities/ticket/types.ts'
import { getArticleAttachmentsLinks } from '#shared/entities/ticket-article/composables/getArticleAttachmentsLinks.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import type { ComputedRef } from 'vue'

interface AttachmentsOptions {
  ticketInternalId: number
  articleInternalId: number
  attachments: ComputedRef<TicketArticleAttachment[]>
}

export const useArticleAttachments = (options: AttachmentsOptions) => {
  const application = useApplicationStore()

  const attachments = computed(() => {
    return options.attachments.value.map((attachment) => {
      const { previewUrl, inlineUrl, canDownload, downloadUrl } =
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
        inline: inlineUrl,
        canDownload,
        downloadUrl,
      }
    })
  })

  return {
    attachments,
  }
}
