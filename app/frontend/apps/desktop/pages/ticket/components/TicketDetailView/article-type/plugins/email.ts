// Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

import { useArticleSecurity } from '#shared/composables/useArticleSecurity.ts'

import type { ChannelModule } from '#desktop/pages/ticket/components/TicketDetailView/article-type/types.ts'
import ArticleMetaSecurity from '#desktop/pages/ticket/components/TicketDetailView/ArticleMeta/ArticleMetaSecurity.vue'

export default <ChannelModule>{
  name: 'email',
  icon: 'mail',
  label: __('Email'),
  additionalFields: [
    { name: 'subject', order: 350, label: __('Subject') },
    {
      name: 'securityState',
      order: 500,
      show: (article) => {
        const { hasError, isEncrypted, isSigned } = useArticleSecurity(article)

        if (isEncrypted.value || isSigned.value) return true

        return hasError.value
      },
      component: ArticleMetaSecurity,
      label: __('Security'),
    },
  ],
}
