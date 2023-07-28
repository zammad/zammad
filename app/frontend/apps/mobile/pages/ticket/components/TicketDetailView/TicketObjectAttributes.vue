<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef } from 'vue'
import type { TicketById } from '#shared/entities/ticket/types.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import CommonSectionMenu from '#mobile/components/CommonSectionMenu/CommonSectionMenu.vue'
import CommonSectionMenuItem from '#mobile/components/CommonSectionMenu/CommonSectionMenuItem.vue'

interface Props {
  ticket: TicketById
}

const props = defineProps<Props>()
const ticketData = toRef(props, 'ticket')

const application = useApplicationStore()

const timeAccountingDisplayUnit = computed(() => {
  switch (application.config.time_accounting_unit) {
    case 'hour':
      return __('hour(s)')
    case 'quarter':
      return __('quarter-hour(s)')
    case 'minute':
      return __('minute(s)')
    case 'custom':
      return application.config.time_accounting_unit_custom
    default:
      return ''
  }
})

const isShown = toRef(() => Boolean(ticketData.value.timeUnit))
</script>

<template>
  <CommonSectionMenu v-if="isShown">
    <CommonSectionMenuItem
      v-if="ticketData.timeUnit"
      :label="__('Accounted Time')"
    >
      {{ ticketData.timeUnit }}
      {{ $t(timeAccountingDisplayUnit) }}
    </CommonSectionMenuItem>
  </CommonSectionMenu>
</template>
