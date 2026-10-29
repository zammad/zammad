// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { computed, toValue, type MaybeRefOrGetter } from 'vue'

import { useAttachments } from '#shared/composables/useAttachments.ts'
import type { TicketArticle } from '#shared/entities/ticket/types.ts'

type UnprocessableEmailArticle = Pick<TicketArticle, 'preferences' | 'attachmentsWithoutInline'>

type UnprocessableEmailAttachmentMarker = 'raw' | 'log'

// The first article of an error ticket carries the flag, with the raw email and the processing log attached.
export const isUnprocessableEmailArticle = (
  article?: Maybe<Pick<TicketArticle, 'preferences'>>,
): boolean => article?.preferences?.email_unprocessable === true

export const useTicketArticleUnprocessableEmail = (
  article: MaybeRefOrGetter<Maybe<UnprocessableEmailArticle> | undefined>,
) => {
  const isUnprocessableEmail = computed(() => isUnprocessableEmailArticle(toValue(article)))

  const { attachments } = useAttachments({
    attachments: computed(() =>
      isUnprocessableEmail.value ? (toValue(article)?.attachmentsWithoutInline ?? []) : [],
    ),
  })

  const findAttachment = (marker: UnprocessableEmailAttachmentMarker) =>
    attachments.value.find((attachment) => attachment.preferences?.email_unprocessable === marker)

  const rawEmail = computed(() => findAttachment('raw'))
  const processingLog = computed(() => findAttachment('log'))

  return { isUnprocessableEmail, rawEmail, processingLog }
}
