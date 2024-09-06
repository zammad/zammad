// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { find } from 'lodash-es'
import { computed, type Ref, type MaybeRef, toValue } from 'vue'

import type { TicketArticle } from '#shared/entities/ticket/types.ts'

// TODO MaybeRef needed? Check...
export const useEmailFileUrls = (
  ticketArticle: MaybeRef<TicketArticle>,
  ticketInternalId: Ref<number>,
) => {
  const article = computed(() => toValue(ticketArticle))

  const originalFormattingUrl = computed(() => {
    if (article.value.type?.name !== 'email') return

    const originalFormattingFile = find(
      article.value.attachmentsWithoutInline,
      (file) => {
        return file.preferences?.['original-format'] === true
      },
    )

    if (!originalFormattingFile) return

    return `/api/v1/ticket_attachment/${ticketInternalId.value}/${article.value.internalId}/${originalFormattingFile.internalId}?disposition=attachment`
  })

  const rawMessageUrl = computed(() => {
    if (article.value.type?.name !== 'email') return

    return `/api/v1/ticket_article_plain/${article.value.internalId}`
  })

  return { originalFormattingUrl, rawMessageUrl }
}
