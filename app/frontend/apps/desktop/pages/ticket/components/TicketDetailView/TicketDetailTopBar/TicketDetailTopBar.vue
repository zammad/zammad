<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { useTicketChannel } from '#shared/entities/ticket/composables/useTicketChannel.ts'
import { useTicketView } from '#shared/entities/ticket/composables/useTicketView.ts'

import TopBarHeader from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/TopBarHeader.vue'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

interface Props {
  hideDetails: boolean
}

defineProps<Props>()

const { ticket } = useTicketInformation()
const { isTicketAgent, isTicketEditable } = useTicketView(ticket)
const { hasChannelAlert, channelAlert } = useTicketChannel(ticket)
</script>

<template>
  <div v-if="isTicketAgent && isTicketEditable && hasChannelAlert">
    <TopBarHeader :hide-details="hideDetails" />

    <CommonAlert
      class="rounded-none px-14 md:grid-cols-none md:justify-center"
      :variant="channelAlert?.variant"
    >
      {{ $t(channelAlert?.text, channelAlert?.textPlaceholder) }}
    </CommonAlert>
  </div>
  <TopBarHeader v-else :hide-details="hideDetails" />
</template>
