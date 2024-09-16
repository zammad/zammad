// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, type Ref } from 'vue'

import type { TicketArticle } from '#shared/entities/ticket/types.ts'

export const useWhatsapp = (article: Ref<TicketArticle>) => {
  const articleDeliveryStatus = computed(() => {
    if (article.value.preferences?.whatsapp?.timestamp_read) {
      return {
        message: __('read by the customer'),
        icon: 'read',
      }
    }

    // desktop has alias for check and check-double
    if (article.value.preferences?.whatsapp?.timestamp_delivered) {
      return { message: __('delivered to the customer'), icon: 'delivered' }
    }

    if (article.value.preferences?.whatsapp?.timestamp_sent) {
      return { message: __('sent to the customer'), icon: 'send' }
    }

    return undefined
  })

  const hasDeliveryStatus = computed(
    () =>
      !!(
        article.value?.preferences?.whatsapp?.timestamp_read ||
        article.value?.preferences?.whatsapp?.timestamp_delivered ||
        article.value?.preferences?.whatsapp?.timestamp_sent
      ),
  )

  return { articleDeliveryStatus, hasDeliveryStatus }
}
