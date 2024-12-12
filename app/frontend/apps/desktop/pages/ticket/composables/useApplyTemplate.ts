// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { storeToRefs } from 'pinia'
import { onBeforeUnmount } from 'vue'
import { useRoute } from 'vue-router'

import { useTicketTemplateStore } from '../stores/ticketTemplate.ts'

export const useApplyTemplate = () => {
  const templateStore = useTicketTemplateStore()

  const { templateList } = storeToRefs(templateStore)

  const { activate, deactivate } = templateStore

  const route = useRoute()

  // TODO: Drop this mechanism once Apollo implements an effective deduplication of subscriptions on the client level.
  //   More information: https://github.com/apollographql/apollo-client/issues/10117
  const usageKey = route.meta.taskbarTabEntityKey ?? 'apply-template'

  activate(usageKey)

  onBeforeUnmount(() => {
    deactivate(usageKey)
  })

  return {
    templateList,
  }
}
