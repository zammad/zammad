<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import { useTicketUpdatesSubscription } from '#shared/entities/ticket/graphql/subscriptions/ticketUpdates.api.ts'
import { EnumTicketStateColorCode, type Ticket } from '#shared/graphql/types.ts'
import SubscriptionHandler from '#shared/server/apollo/handler/SubscriptionHandler.ts'
import { useSessionStore } from '#shared/stores/session.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import CommonTicketStateIndicatorIcon from '#desktop/components/CommonTicketStateIndicatorIcon/CommonTicketStateIndicatorIcon.vue'
import CommonUpdateIndicator from '#desktop/components/CommonUpdateIndicator/CommonUpdateIndicator.vue'
import { useUserTaskbarTabLink } from '#desktop/composables/useUserTaskbarTabLink.ts'
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
  {
    // NB: Silence toast notifications for particular errors, these will be handled by the layout taskbar tab component.
    errorCallback: (errorHandler) =>
      errorHandler.type !== GraphQLErrorTypes.Forbidden &&
      errorHandler.type !== GraphQLErrorTypes.RecordNotFound,
  },
)

const { updateTaskbarTab } = useUserCurrentTaskbarTabsStore()

const updateNotifyFlag = (notify: boolean) => {
  if (!props.taskbarTab.taskbarTabId) return

  updateTaskbarTab(props.taskbarTab.taskbarTabId, {
    ...props.taskbarTab,
    notify,
  })
}

const { tabLinkInstance, taskbarTabActive } = useUserTaskbarTabLink(
  toRef(props, 'taskbarTab'),
  () => {
    // Reset the notify flag when the tab becomes active.
    if (props.taskbarTab.notify) updateNotifyFlag(false)
  },
)

const isTicketUpdated = computed(() => {
  if (taskbarTabActive.value) return false
  return props.taskbarTab.notify
})

const { user } = useSessionStore()

// Set the notify flag whenever the result is received from the subscription.
ticketUpdatesSubscription.onSubscribed().then(() => {
  ticketUpdatesSubscription.onResult((result) => {
    if (
      !result.data?.ticketUpdates ||
      !props.taskbarTab.entity ||
      props.taskbarTab.notify
    )
      return

    const { ticket } = result.data.ticketUpdates

    // Skip setting the notify flag if:
    //   - the ticket entity is in the same state
    //   - the ticket was updated by the current user
    if (
      props.taskbarTab.entity.updatedAt === ticket?.updatedAt ||
      ticket?.updatedBy?.id === user?.id
    )
      return

    updateNotifyFlag(true)
  })
})

const currentState = computed(() => {
  return props.taskbarTab.entity?.state?.name || ''
})

const currentTitle = computed(() => {
  return props.taskbarTab.entity?.title || ''
})

const currentStateColorCode = computed(
  () =>
    props.taskbarTab.entity?.stateColorCode || EnumTicketStateColorCode.Open,
)

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
    v-if="taskbarTabLink"
    ref="tabLinkInstance"
    v-tooltip="currentViewTitle"
    class="flex grow gap-2 rounded-md px-2 py-3 hover:no-underline focus-visible:rounded-md focus-visible:outline-none group-hover/tab:bg-blue-600 group-hover/tab:dark:bg-blue-900"
    :link="taskbarTabLink"
    :class="{
      [activeBackgroundColor]: taskbarTabActive,
    }"
    internal
  >
    <div class="relative">
      <CommonUpdateIndicator v-if="isTicketUpdated" />
      <CommonTicketStateIndicatorIcon
        class="group-focus-visible/link:text-white"
        :class="{
          '!text-white': taskbarTabActive,
        }"
        :color-code="currentStateColorCode"
        :label="currentState"
        icon-size="small"
      />
    </div>
    <CommonLabel
      class="-:text-gray-300 -:dark:text-neutral-400 block truncate group-focus-visible/link:text-white group-hover/tab:dark:text-white"
      :class="{
        '!text-white': taskbarTabActive,
      }"
    >
      {{ currentTitle }}
    </CommonLabel>
  </CommonLink>
</template>
