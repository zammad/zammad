<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { ComputedRef } from 'vue'
import { computed } from 'vue'
import useApplicationStore from '@shared/stores/application'
import type { DateTimeFormat } from './types'

export interface Props {
  dateTime: string
  format?: DateTimeFormat
}

type OutputFormat = Exclude<DateTimeFormat, 'configured'>

const props = withDefaults(defineProps<Props>(), {
  format: 'configured',
})

const application = useApplicationStore()

const outputFormat: ComputedRef<OutputFormat> = computed(() => {
  if (props.format !== 'configured') return props.format

  return application.config.pretty_date_format === 'relative'
    ? 'relative'
    : 'absolute'
})
</script>

<template>
  <span v-if="outputFormat === 'absolute'">{{ i18n.dateTime(dateTime) }}</span>
  <span v-else :title="i18n.dateTime(dateTime)">{{
    i18n.relativeDateTime(dateTime)
  }}</span>
</template>
