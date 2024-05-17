<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed, toRef, ref } from 'vue'

import type { TicketById } from '#shared/entities/ticket/types.ts'
import { useApplicationStore } from '#shared/stores/application.ts'
import { capitalize } from '#shared/utils/formatter.ts'

import CommonSectionMenu from '#mobile/components/CommonSectionMenu/CommonSectionMenu.vue'
import CommonSectionMenuItem from '#mobile/components/CommonSectionMenu/CommonSectionMenuItem.vue'
import CommonShowMoreButton from '#mobile/components/CommonShowMoreButton/CommonShowMoreButton.vue'

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
  if (!application.config.time_accounting_types) return []

  if (
    props.ticket.timeUnitsPerType &&
    props.ticket.timeUnitsPerType.length === 1 &&
    props.ticket.timeUnitsPerType[0].name === 'None'
  ) {
    return []
  }

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
      <div class="grid grid-cols-[1fr_auto_auto] py-2" role="list">
        <template
          v-for="({ name, timeUnit }, index) of shownUnits"
          :key="index"
        >
          <div class="col-[1] truncate text-white/80 ltr:mr-2 rtl:ml-2">
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
