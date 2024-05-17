// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { computed, type Ref } from 'vue'

import type { TicketById } from '#shared/entities/ticket/types.ts'

import { getTicketView } from '../utils/getTicketView.ts'

export const useTicketView = (ticket: Ref<TicketById | undefined>) => {
  const view = computed(() => ticket.value && getTicketView(ticket.value))

  const isTicketEditable = computed(() => view.value?.isTicketEditable || false)
  const isTicketCustomer = computed(() => view.value?.isTicketCustomer || false)
  const isTicketAgent = computed(() => view.value?.isTicketAgent || false)

  return { isTicketAgent, isTicketCustomer, isTicketEditable }
}
