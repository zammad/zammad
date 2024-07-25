// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'

import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

export const useTicketArticleReply = () => {
  const { ticket } = useTicketInformation()

  const canUpdateTicket = computed(() => !!ticket.value?.policy.update)

  return { canUpdateTicket }
}
