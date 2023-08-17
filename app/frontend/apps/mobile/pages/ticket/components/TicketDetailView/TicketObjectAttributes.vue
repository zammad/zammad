<!-- Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef, ref } from 'vue'
import type { TicketById } from '#shared/entities/ticket/types.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import CommonSectionMenu from '#mobile/components/CommonSectionMenu/CommonSectionMenu.vue'
import CommonSectionMenuItem from '#mobile/components/CommonSectionMenu/CommonSectionMenuItem.vue'
import CommonShowMoreButton from '#mobile/components/CommonShowMoreButton/CommonShowMoreButton.vue'
import { capitalize } from '#shared/utils/formatter.ts'

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

const showAll = ref(false)
const MIN_SHOWN = 3

const allUnits = computed(() => {
  return props.ticket.timeUnitsPerType || []
})

const shownUnits = computed(() => {
  if (showAll.value) return allUnits.value
  return allUnits.value.slice(0, MIN_SHOWN)
})
</script>

<template>
  <CommonSectionMenu v-if="isShown">
    <CommonSectionMenuItem
      v-if="ticketData.timeUnit"
      :label="__('Total Accounted Time')"
    >
      {{ ticketData.timeUnit }}
      {{ $t(timeAccountingDisplayUnit) }}
    </CommonSectionMenuItem>

    <CommonSectionMenuItem
      v-if="allUnits.length"
      data-test-id="timeUnitsEntries"
    >
      <div class="grid grid-cols-[max-content_1fr] py-2" role="list">
        <template
          v-for="({ name, timeUnit }, index) of shownUnits"
          :key="index"
        >
          <div class="text-white/80 max-w-[10rem] truncate rtl:ml-2 ltr:mr-2">
            {{ capitalize($t(name)) }}
          </div>
          <div>{{ timeUnit }} {{ $t(timeAccountingDisplayUnit) }}</div>
        </template>
      </div>
    </CommonSectionMenuItem>

    <CommonShowMoreButton
      :entities="shownUnits"
      :total-count="allUnits.length"
      @click="showAll = true"
    />
  </CommonSectionMenu>
</template>
