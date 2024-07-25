// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { find } from 'lodash-es'
import { computed, type MaybeRef, toValue } from 'vue'

import type { TicketArticle } from '#shared/entities/ticket/types'

import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

export const useEmailFileUrls = (ticketArticle: MaybeRef<TicketArticle>) => {
  const article = computed(() => toValue(ticketArticle))
  const { ticket } = useTicketInformation()

  const originalFormattingUrl = computed(() => {
    const originalFormattingFile = find(
      article.value.attachmentsWithoutInline,
      (file) => {
        return file.preferences?.['original-format'] === true
      },
    )

    if (!originalFormattingFile) return

    return `/ticket_attachment/${ticket.value.internalId}/${article.value.internalId}/${originalFormattingFile.internalId}?disposition=attachment`
  })

  const rawMessageUrl = computed(
    () => `/api/v1/ticket_article_plain/${article.value.internalId}`,
  )

  return { originalFormattingUrl, rawMessageUrl }
}
