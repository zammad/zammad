<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref, toRef, watch } from 'vue'

import { useTicketUpdatesSubscription } from '#shared/entities/ticket/graphql/subscriptions/ticketUpdates.api.ts'
import { EnumTicketStateColorCode, type Ticket } from '#shared/graphql/types.ts'
import SubscriptionHandler from '#shared/server/apollo/handler/SubscriptionHandler.ts'

import CommonTicketStateIndicatorIcon from '#desktop/components/CommonTicketStateIndicatorIcon/CommonTicketStateIndicatorIcon.vue'
import CommonUpdateIndicator from '#desktop/components/CommonUpdateIndicator/CommonUpdateIndicator.vue'
import { useTicketNumber } from '#desktop/pages/ticket/composables/useTicketNumber.ts'

import type { UserTaskbarTabEntityProps } from '../types.ts'

const props = defineProps<UserTaskbarTabEntityProps<Ticket>>()

const { ticketNumberWithTicketHook } = useTicketNumber(toRef(props, 'entity'))

const ticketUpdatesSubscription = new SubscriptionHandler(
  useTicketUpdatesSubscription({ ticketId: props.entity.id, initial: true }), // TODO: maybe only true, when it's not the current active tab, but is it really a overhead?
)

const ticketLink = ref()

const isTicketUpdated = ref(false)

// TODO: currently after reload the information is gone, in the old interface the "notify" column in the taskbar model was used to remember this.
// TODO: Idea for the future: Could we not use taskbar.lastContact < ticket.updatedAt instead of a flag?!
// Not relevant for the initial subscription request.
ticketUpdatesSubscription.onSubscribed().then(() => {
  // Set the updated flag whenever the result is received from the subscription.
  ticketUpdatesSubscription.onResult(() => {
    // Skip flagging currently active tab.
    if (ticketLink.value?.isExactActive) return

    isTicketUpdated.value = true
  })
})

// Reset the updated flag when the tab becomes active.
watch(
  () => ticketLink.value?.isExactActive,
  (isExactActive) => {
    if (!isTicketUpdated.value || !isExactActive) return

    isTicketUpdated.value = false
  },
)

const currentState = computed(() => {
  return props.entity.state.name
})

const currentTitle = computed(() => {
  return props.entity.title
})

const currentStateColorCode = computed(() => {
  return props.entity.stateColorCode
})

const activeBackgroundColor = computed(() => {
  switch (currentStateColorCode.value) {
    case EnumTicketStateColorCode.Closed:
      return '!bg-green-400 text-white dark:text-white'
    case EnumTicketStateColorCode.Pending:
      return '!bg-stone-400 text-white dark:text-white'
    case EnumTicketStateColorCode.Escalating:
      return '!bg-red-300 text-white dark:text-white'
    case EnumTicketStateColorCode.Open:
    default:
      return '!bg-yellow-500 text-white dark:text-white'
  }
})

const currentViewTitle = computed(
  () => `${ticketNumberWithTicketHook.value} - ${props.entity.title}`,
)
</script>

<template>
  <CommonLink
    ref="ticketLink"
    v-tooltip="currentViewTitle"
    class="flex grow gap-2 rounded-md px-2 py-3 hover:no-underline focus-visible:rounded-md focus-visible:outline-none group-hover/tab:bg-blue-600 group-hover/tab:dark:bg-blue-900"
    :link="taskbarTabLink"
    :exact-active-class="activeBackgroundColor"
    internal
  >
    <div class="relative">
      <CommonUpdateIndicator v-if="isTicketUpdated" />
      <CommonTicketStateIndicatorIcon
        :color-code="currentStateColorCode"
        :label="currentState"
        icon-size="small"
      />
    </div>
    <CommonLabel
      class="-:text-gray-300 -:dark:text-neutral-400 line-clamp-1 group-hover/tab:dark:text-white"
    >
      {{ currentTitle }}
    </CommonLabel>
  </CommonLink>
</template>

<style scoped>
a.router-link-active span {
  @apply text-white;
}
</style>
