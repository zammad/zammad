// Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

import { computed } from 'vue'
import type { Ref } from 'vue'
import { MutationHandler } from '@shared/server/apollo/handler'
import { useMentionSubscribeMutation } from '@shared/entities/ticket/graphql/mutations/subscribe.api'
import { useMentionUnsubscribeMutation } from '@shared/entities/ticket/graphql/mutations/unsubscribe.api'
import type { TicketQuery } from '@shared/graphql/types'
import { useTicketView } from '@shared/entities/ticket/composables/useTicketView'
import type { TicketById } from '@shared/entities/ticket/types'

export const useTicketSubscribe = (ticket: Ref<TicketById | undefined>) => {
  const { isTicketAgent } = useTicketView(ticket)
  const canManageSubscription = computed(() => isTicketAgent.value)

  const createTicketCacheUpdater = (subscribed: boolean) => {
    return (previousQuery: Record<string, unknown>) => {
      const prev = previousQuery as TicketQuery
      if (!ticket.value || !prev || prev.ticket?.id !== ticket.value.id) {
        return prev
      }
      return {
        ticket: {
          ...prev.ticket,
          subscribed,
        },
      }
    }
  }

  const subscribeHanler = new MutationHandler(
    useMentionSubscribeMutation({
      updateQueries: {
        ticket: createTicketCacheUpdater(true),
      },
    }),
  )
  const unsubscribeMutation = new MutationHandler(
    useMentionUnsubscribeMutation({
      updateQueries: {
        ticket: createTicketCacheUpdater(false),
      },
    }),
  )

  const isSubscriptionLoading = computed(() => {
    return (
      subscribeHanler.loading().value || unsubscribeMutation.loading().value
    )
  })

  const subscribe = async (ticketId: string) => {
    const result = await subscribeHanler.send({ ticketId })
    return !!result?.mentionSubscribe?.success
  }
  const unsubscribe = async (ticketId: string) => {
    const result = await unsubscribeMutation.send({ ticketId })
    return !!result?.mentionUnsubscribe?.success
  }

  const toggleSubscribe = async () => {
    if (!ticket.value || isSubscriptionLoading.value) return false
    const { id, subscribed } = ticket.value

    if (!subscribed) {
      return subscribe(id)
    }
    return unsubscribe(id)
  }

  const isSubscribed = computed(() => !!ticket.value?.subscribed)

  return {
    isSubscriptionLoading,
    isSubscribed,
    toggleSubscribe,
    canManageSubscription,
  }
}
