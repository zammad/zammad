<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { storeToRefs } from 'pinia'
import { computed } from 'vue'

import {
  NotificationTypes,
  useNotifications,
} from '#shared/components/CommonNotifications/index.ts'
import { EnumTicketScreenBehavior } from '#shared/graphql/types.ts'
import { MutationHandler } from '#shared/server/apollo/handler/index.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { useSessionStore } from '#shared/stores/session.ts'

import CommonDropdown from '#desktop/components/CommonDropdown/CommonDropdown.vue'
import type { MenuItem } from '#desktop/components/CommonPopoverMenu/types.ts'
import { useUserCurrentTicketScreenBehaviorMutation } from '#desktop/entities/user/current/graphql/mutations/userCurrentTicketScreenBehavior.api.ts'
import {
  behaviorOptionLookup,
  behaviorOptions,
} from '#desktop/pages/ticket/components/TicketDetailView/TicketScreenBehavior/behaviorOptions.ts'

const sessionStore = useSessionStore()
const { setUserPreference } = sessionStore
const { user } = storeToRefs(sessionStore)

const applicationStore = useApplicationStore()
const { config } = storeToRefs(applicationStore)

const { notify } = useNotifications()

const ticketScreenBehaviorMutation = new MutationHandler(
  useUserCurrentTicketScreenBehaviorMutation(),
)

const secondaryAction = computed<EnumTicketScreenBehavior>(
  () =>
    user.value?.preferences?.secondaryAction ||
    config.value.ticket_secondary_action ||
    EnumTicketScreenBehavior.StayOnTab,
)

const selectedItem = computed({
  get: () => behaviorOptionLookup[secondaryAction.value],
  set: (item: MenuItem) => {
    ticketScreenBehaviorMutation
      .send({
        behavior: item.key as EnumTicketScreenBehavior,
      })
      .then(() => {
        setUserPreference('secondaryAction', item.key)
        notify({
          id: 'ticket-screen-behavior-updated',
          type: NotificationTypes.Success,
          message: __('Ticket screen behavior updated successfully'),
        })
      })
  },
})
</script>

<template>
  <CommonDropdown
    v-model="selectedItem"
    :items="behaviorOptions"
    orientation="top"
  />
</template>
