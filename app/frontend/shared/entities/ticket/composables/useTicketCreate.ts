// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'
import { useApplicationStore } from '@shared/stores/application'

export const useTicketCreate = () => {
  const application = useApplicationStore()

  const ticketCreateEnabled = computed(() => {
    return application.config.customer_ticket_create as boolean
  })

  return { ticketCreateEnabled }
}
