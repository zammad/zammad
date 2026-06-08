// Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

import { useWhatsapp } from '#shared/entities/ticket/channel/composables/useWhatsapp.ts'

import type { ChannelModule } from '#desktop/pages/ticket/components/TicketDetailView/article-type/types.ts'
import ArticleMetaWhatsappMessageStatus from '#desktop/pages/ticket/components/TicketDetailView/ArticleMeta/ArticleMetaWhatsappMessageStatus.vue'

export default <ChannelModule>{
  name: 'whatsapp message',
  label: __('WhatsApp message'),
  metaLabel: __('whatsapp message'),
  icon: 'whatsapp',
  additionalFields: [
    {
      name: 'preferences.whatsapp',
      label: __('Message status'),
      show: (article) => {
        const { hasDeliveryStatus } = useWhatsapp(article)
        return hasDeliveryStatus.value
      },
      order: 400,
      component: ArticleMetaWhatsappMessageStatus,
    },
  ],
}
