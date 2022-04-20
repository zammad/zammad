<!-- Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import useApplicationConfigStore from '@common/stores/application/config'
import { DateTimeFormat } from '@common/types/dateTime'
import { computed, ComputedRef } from 'vue'

export interface Props {
  dateTime: string
  format?: DateTimeFormat
}

type OutputFormat = Exclude<DateTimeFormat, 'configured'>

const props = withDefaults(defineProps<Props>(), {
  format: 'configured',
})

const configStore = useApplicationConfigStore()

const outputFormat: ComputedRef<OutputFormat> = computed(() => {
  if (props.format !== 'configured') return props.format

  return configStore.value.pretty_date_format === 'relative'
    ? 'relative'
    : 'absolute'
})
</script>

<template>
  <span v-if="outputFormat === 'absolute'">{{ i18n.dateTime(dateTime) }}</span>
  <span v-else v-bind:title="i18n.dateTime(dateTime)">{{
    i18n.relativeDateTime(dateTime)
  }}</span>
</template>
