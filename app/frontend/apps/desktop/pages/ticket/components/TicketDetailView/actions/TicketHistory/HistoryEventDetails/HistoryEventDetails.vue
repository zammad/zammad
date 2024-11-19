<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import { i18n } from '#shared/i18n.ts'
import { capitalize } from '#shared/utils/formatter.ts'

import type { EventActionOutput } from '../types.ts'

interface Props {
  event: EventActionOutput
}

const { event } = defineProps<Props>()

const descriptionOutput = computed(() => {
  if (event.description) return i18n.t(event.description)

  return (
    [event.entityName, event.attributeName]
      .filter((item) => !!item)
      .map((item) => i18n.t(item as string))
      .join(' ') || null
  )
})
</script>

<template>
  <span>
    <CommonLabel class="text-gray-100 ltr:mr-1 rtl:ml-1 dark:text-neutral-400">
      {{ capitalize($t(event.actionName)) }}
    </CommonLabel>

    <CommonLabel
      v-if="descriptionOutput"
      class="text-gray-100 dark:text-neutral-400"
      >{{ descriptionOutput }}</CommonLabel
    >

    <CommonLabel
      v-if="event.details"
      class="cursor-text rounded bg-neutral-200 px-0.5 font-mono text-black dark:bg-gray-400 dark:text-white"
      :class="{
        'ltr:mr-1 rtl:ml-1': event.showSeparator || event.additionalDetails,
        'ltr:ml-1 rtl:mr-1': descriptionOutput,
      }"
      >{{ event.details }}</CommonLabel
    >

    <CommonLabel
      v-if="event.showSeparator && event.details && event.additionalDetails"
      class="text-gray-100 dark:text-neutral-400"
      :class="{
        'ltr:mr-1 rtl:ml-1': event.details || event.additionalDetails,
      }"
      >→</CommonLabel
    >

    <CommonLabel
      v-if="event.additionalDetails"
      class="cursor-text rounded bg-neutral-200 px-0.5 font-mono text-black dark:bg-gray-400 dark:text-white"
      >{{ event.additionalDetails }}</CommonLabel
    >
  </span>
</template>
