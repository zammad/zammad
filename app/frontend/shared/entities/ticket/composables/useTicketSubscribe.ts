// Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

import { keyBy } from 'lodash-es'
import { computed } from 'vue'

import { useTicketView } from '#shared/entities/ticket/composables/useTicketView.ts'
import { useMentionSubscribeMutation } from '#shared/entities/ticket/graphql/mutations/subscribe.api.ts'
import { useMentionUnsubscribeMutation } from '#shared/entities/ticket/graphql/mutations/unsubscribe.api.ts'
import type { TicketById } from '#shared/entities/ticket/types.ts'
import type { TicketQuery } from '#shared/graphql/types.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import type { Ref } from 'vue'

export const useTicketSubscribe = (ticket: Ref<TicketById | undefined>) => {
  const { isTicketAgent } = useTicketView(ticket)
  const canManageSubscription = computed(() => isTicketAgent.value)

  const session = useSessionStore()

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

  const subscribeHandler = new MutationHandler(
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
      subscribeHandler.loading().value || unsubscribeMutation.loading().value
    )
  })

  const subscribe = async (ticketId: string) => {
    const result = await subscribeHandler.send({ ticketId })
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

  const subscribers = computed(
    () =>
      ticket.value?.mentions?.edges
        ?.filter(({ node }) => node.user.active)
        .map(({ node }) => ({
          user: node.user,
          access: node.userTicketAccess,
        })) || [],
  )

  const subscribersWithoutMe = computed(
    () =>
      ticket.value?.mentions?.edges
        ?.filter(({ node }) => node.user.id !== session.userId)
        .map(({ node }) => node.user) || [],
  )

  const subscribersAccessLookup = computed(() =>
    keyBy(
      ticket.value?.mentions?.edges
        ?.filter(({ node }) => node.user.id !== session.userId)
        .map(({ node }) => ({
          userId: node.user.id,
          access: node.userTicketAccess,
        })) || [],
      'userId',
    ),
  )

  const hasMe = computed(() => {
    if (!ticket.value?.mentions) return false

    return ticket.value.mentions.edges.some(
      ({ node }) => node.user.id === session.userId,
    )
  })

  const totalSubscribers = computed(() => {
    if (!ticket.value?.mentions) return 0

    return ticket.value.mentions.totalCount
  })

  const totalSubscribersWithoutMe = computed(() => {
    if (!ticket.value?.mentions) return 0

    // -1 for current user, who is shown as toggler
    return ticket.value.mentions.totalCount - (hasMe.value ? 1 : 0)
  })

  return {
    isSubscriptionLoading,
    isSubscribed,
    toggleSubscribe,
    canManageSubscription,
    subscribers,
    totalSubscribers,
    subscribersWithoutMe,
    subscribersAccessLookup,
    totalSubscribersWithoutMe,
    hasMe,
  }
}
