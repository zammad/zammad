// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, type ComputedRef } from 'vue'

import { useTicketCreateArticleType } from '#shared/entities/ticket/composables/useTicketCreateArticleType.ts'
import { useTicketCreateView } from '#shared/entities/ticket/composables/useTicketCreateView.ts'
import type { TicketCreateArticleType } from '#shared/entities/ticket/types.ts'
import { i18n } from '#shared/i18n.ts'

export const useTicketCreateTitle = (
  currentTitle: ComputedRef<string>,
  currentArticleType: ComputedRef<string>,
) => {
  const { isTicketCustomer } = useTicketCreateView()

  const { ticketCreateArticleType, defaultTicketCreateArticleType } =
    useTicketCreateArticleType()

  const currentViewTitle = computed(() => {
    // Customer users should get a generic title prefix, since they cannot control the type of the first article.
    if (isTicketCustomer.value) {
      if (!currentTitle.value) return i18n.t('New Ticket')

      return i18n.t('New Ticket: %s', currentTitle.value)
    }

    if (!currentArticleType.value) {
      return i18n.t(
        ticketCreateArticleType[defaultTicketCreateArticleType]?.label,
      )
    }

    const createArticleTypeKey =
      currentArticleType.value as TicketCreateArticleType

    if (!currentTitle.value)
      return i18n.t(ticketCreateArticleType[createArticleTypeKey]?.label)

    return i18n.t(
      ticketCreateArticleType[createArticleTypeKey]?.title,
      currentTitle.value,
    )
  })

  return {
    currentViewTitle,
  }
}
