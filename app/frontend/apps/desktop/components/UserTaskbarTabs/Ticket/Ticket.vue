<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'

import { useTicketUpdatesSubscription } from '#shared/entities/ticket/graphql/subscriptions/ticketUpdates.api.ts'
import { EnumTicketStateColorCode, type Ticket } from '#shared/graphql/types.ts'
import SubscriptionHandler from '#shared/server/apollo/handler/SubscriptionHandler.ts'
import { GraphQLErrorTypes } from '#shared/types/error.ts'

import CommonTicketStateIndicatorIcon from '#desktop/components/CommonTicketStateIndicator/CommonTicketStateIndicatorIcon.vue'
import CommonUpdateIndicator from '#desktop/components/CommonUpdateIndicator/CommonUpdateIndicator.vue'
import { useUserTaskbarTab } from '#desktop/composables/useUserTaskbarTab.ts'
import { useTicketNumber } from '#desktop/pages/ticket/composables/useTicketNumber.ts'

import type { UserTaskbarTabEntityProps } from '../types.ts'

const props = defineProps<UserTaskbarTabEntityProps<Ticket>>()

const { ticketNumberWithTicketHook } = useTicketNumber(toRef(props.taskbarTab, 'entity'))

new SubscriptionHandler(
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

const { tabLinkInstance, taskbarTabActive } = useUserTaskbarTab(toRef(props, 'taskbarTab'))

const isTicketUpdated = computed(() => {
  return props.taskbarTab.notify
})

const currentState = computed(() => {
  return props.taskbarTab.entity?.state?.name || ''
})

const currentTitle = computed(() => {
  return props.taskbarTab.entity?.title || ''
})

const currentStateColorCode = computed(
  () => props.taskbarTab.entity?.stateColorCode || EnumTicketStateColorCode.Open,
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
    class="flex grow items-center gap-2 px-2 py-3 hover:no-underline! group-hover/tab:dark:bg-blue-900"
    :link="taskbarTabLink"
    :class="{
      [activeBackgroundColor]: taskbarTabActive,
      'group-hover/tab:bg-blue-60': collapsed,
      'rounded-lg!': !collapsed,
    }"
    internal
  >
    <div class="relative">
      <CommonUpdateIndicator v-if="isTicketUpdated" />
      <CommonTicketStateIndicatorIcon
        :class="{
          'text-white!': taskbarTabActive,
        }"
        :color-code="currentStateColorCode"
        :label="currentState"
        icon-size="tiny"
      />
    </div>
    <CommonLabel
      class="block! truncate text-gray-300 dark:text-neutral-400 group-hover/tab:dark:text-white"
      :class="{
        'text-white!': taskbarTabActive,
      }"
    >
      {{ currentTitle }}
    </CommonLabel>
  </CommonLink>
</template>
