<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

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
  <div>
    <CommonLabel v-if="event.sentenceDescription" class="me-1 text-gray-100 dark:text-neutral-400">
      {{ $t(event.sentenceDescription) }}
    </CommonLabel>

    <template v-else>
      <CommonLabel class="me-1 text-gray-100 dark:text-neutral-400">
        {{ capitalize($t(event.actionName)) }}
      </CommonLabel>

      <CommonLabel v-if="descriptionOutput" class="text-gray-100 dark:text-neutral-400">{{
        descriptionOutput
      }}</CommonLabel>
    </template>

    <CommonLabel
      v-if="event.details"
      class="max-w-md cursor-text rounded bg-neutral-200 px-0.5 font-mono break-word text-black dark:bg-gray-400 dark:text-white"
      :class="{
        'me-1': event.showSeparator || event.additionalDetails,
        'ms-1': descriptionOutput,
      }"
      >{{ event.details }}</CommonLabel
    >

    <CommonLabel
      v-if="event.showSeparator && event.details && event.additionalDetails"
      class="text-gray-100 dark:text-neutral-400"
      :class="{
        'me-1': event.details || event.additionalDetails,
      }"
      >→</CommonLabel
    >

    <CommonLabel
      v-if="event.additionalDetails"
      class="cursor-text rounded bg-neutral-200 px-0.5 font-mono break-word text-black dark:bg-gray-400 dark:text-white"
      >{{ event.additionalDetails }}</CommonLabel
    >
  </div>
</template>
