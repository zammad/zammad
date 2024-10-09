<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { useTouchDevice } from '#shared/composables/useTouchDevice.ts'
import { useTicketChannel } from '#shared/entities/ticket/composables/useTicketChannel.ts'
import { useTicketView } from '#shared/entities/ticket/composables/useTicketView.ts'

import TopBarHeader from '#desktop/pages/ticket/components/TicketDetailView/TicketDetailTopBar/TopBarHeader.vue'
import { useTicketInformation } from '#desktop/pages/ticket/composables/useTicketInformation.ts'

interface Props {
  hideDetails: boolean
}

const { hideDetails } = defineProps<Props>()

const isHovering = defineModel<boolean>('hover', {
  required: false,
})

const { ticket } = useTicketInformation()
const { isTicketAgent, isTicketEditable } = useTicketView(ticket)
const { hasChannelAlert, channelAlert } = useTicketChannel(ticket)

const { isTouchDevice } = useTouchDevice()

const events = computed(() => {
  if (isTouchDevice.value)
    return {
      touchstart() {
        isHovering.value = true
      },
      touchend() {
        isHovering.value = false
      },
    }

  return {
    mouseenter() {
      isHovering.value = true
    },
    mouseleave() {
      isHovering.value = false
    },
  }
})
</script>

<template>
  <div
    v-if="isTicketAgent && isTicketEditable && hasChannelAlert"
    class="z-10"
    :tabindex="hideDetails ? 0 : -1"
    v-on="events"
  >
    <TopBarHeader :hide-details="hideDetails" />

    <CommonAlert
      class="rounded-none px-14 md:grid-cols-none md:justify-center"
      :variant="channelAlert?.variant"
    >
      {{ $t(channelAlert?.text, channelAlert?.textPlaceholder) }}
    </CommonAlert>
  </div>
  <TopBarHeader v-else :hide-details="hideDetails" v-on="events" />
</template>
