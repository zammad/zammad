<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { i18n } from '#shared/i18n.ts'
import { useApplicationStore } from '#shared/stores/application.ts'

import type { DateTimeType, DateTimeAbsoluteFormat } from './types.ts'
import type { ComputedRef } from 'vue'

export interface Props {
  dateTime: string
  type?: DateTimeType
  absoluteFormat?: DateTimeAbsoluteFormat
}

type OutputType = Exclude<DateTimeType, 'configured'>

const props = withDefaults(defineProps<Props>(), {
  type: 'configured',
  absoluteFormat: 'datetime',
})

const application = useApplicationStore()

const outputFormat: ComputedRef<OutputType> = computed(() => {
  if (props.type !== 'configured') return props.type

  return application.config.pretty_date_format === 'relative'
    ? 'relative'
    : 'absolute'
})

const outputAbsoluteDate = computed(() => {
  if (props.absoluteFormat === 'date') return i18n.date(props.dateTime)
  return i18n.dateTime(props.dateTime)
})
</script>

<template>
  <time v-if="outputFormat === 'absolute'" data-test-id="date-time-absolute">
    <slot name="prefix" />
    {{ outputAbsoluteDate }}
  </time>
  <time
    v-else
    v-tooltip="i18n.dateTime(dateTime)"
    :datetime="dateTime"
    data-test-id="date-time-relative"
  >
    <slot name="prefix" />
    {{ i18n.relativeDateTime(dateTime) }}
  </time>
</template>
