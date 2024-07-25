<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, ref, toRef, watch } from 'vue'

import { useTicketUpdatesSubscription } from '#shared/entities/ticket/graphql/subscriptions/ticketUpdates.api.ts'
import { EnumTicketStateColorCode, type Ticket } from '#shared/graphql/types.ts'
import SubscriptionHandler from '#shared/server/apollo/handler/SubscriptionHandler.ts'

import CommonTicketStateIndicatorIcon from '#desktop/components/CommonTicketStateIndicatorIcon/CommonTicketStateIndicatorIcon.vue'
import CommonUpdateIndicator from '#desktop/components/CommonUpdateIndicator/CommonUpdateIndicator.vue'
import { useUserCurrentTaskbarTabsStore } from '#desktop/entities/user/current/stores/taskbarTabs.ts'
import { useTicketNumber } from '#desktop/pages/ticket/composables/useTicketNumber.ts'

import type { UserTaskbarTabEntityProps } from '../types.ts'

const props = defineProps<UserTaskbarTabEntityProps<Ticket>>()

const { ticketNumberWithTicketHook } = useTicketNumber(
  toRef(props.taskbarTab, 'entity'),
)

const ticketUpdatesSubscription = new SubscriptionHandler(
  useTicketUpdatesSubscription({
    ticketId: props.taskbarTab.entity!.id,
    initial: true,
  }),
)

const ticketLink = ref()

const isTicketUpdated = computed(() => {
  if (ticketLink.value?.isExactActive) return false
  return props.taskbarTab.notify
})

const { updateTaskbarTab } = useUserCurrentTaskbarTabsStore()

const updateNotifyFlag = (notify: boolean) => {
  if (!props.taskbarTab.taskbarTabId) return

  updateTaskbarTab(props.taskbarTab.taskbarTabId, {
    ...props.taskbarTab,
    notify,
  })
}

// Set the notify flag whenever the result is received from the subscription.
ticketUpdatesSubscription.onSubscribed().then(() => {
  ticketUpdatesSubscription.onResult(() => {
    if (props.taskbarTab.notify) return

    updateNotifyFlag(true)
  })
})

// Reset the notify flag when the tab becomes active.
watch(
  () => ticketLink.value?.isExactActive,
  (isExactActive) => {
    if (!isExactActive || !props.taskbarTab.notify) return

    updateNotifyFlag(false)
  },
)

const currentState = computed(() => {
  return props.taskbarTab.entity?.state?.name || ''
})

const currentTitle = computed(() => {
  return props.taskbarTab.entity?.title || ''
})

const currentStateColorCode = computed(() => {
  return (
    props.taskbarTab.entity?.stateColorCode || EnumTicketStateColorCode.Open
  )
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
  () => `${ticketNumberWithTicketHook.value} - ${currentTitle.value}`,
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
      class="-:text-gray-300 -:dark:text-neutral-400 block truncate group-hover/tab:dark:text-white"
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
