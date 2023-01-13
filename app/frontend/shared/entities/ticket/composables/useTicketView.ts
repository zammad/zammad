// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { computed, type Ref } from 'vue'
import type { TicketById } from '@shared/entities/ticket/types'
import { getTicketView } from '../utils/getTicketView'

export const useTicketView = (ticket: Ref<TicketById | undefined>) => {
  const view = computed(() => ticket.value && getTicketView(ticket.value))

  const isTicketEditable = computed(() => view.value?.isTicketEditable || false)
  const isTicketCustomer = computed(() => view.value?.isTicketCustomer || false)
  const isTicketAgent = computed(() => view.value?.isTicketAgent || false)

  return { isTicketAgent, isTicketCustomer, isTicketEditable }
}
