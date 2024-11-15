<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { EventActionContent } from '../types'

interface Props {
  changes: EventActionContent
}

const { changes } = defineProps<Props>()
</script>

<template>
  <span>
    <CommonLabel
      v-if="changes.description"
      class="text-gray-100 dark:text-neutral-400"
      >{{ $t(changes.description) }}</CommonLabel
    >

    <CommonLabel
      v-if="changes.details"
      class="cursor-text rounded bg-neutral-200 px-0.5 font-mono text-black dark:bg-gray-400 dark:text-white"
      :class="{
        'ltr:mr-1 rtl:ml-1': changes.showSeparator || changes.additionalDetails,
        'ltr:ml-1 rtl:mr-1': changes.description,
      }"
      >{{ changes.details }}</CommonLabel
    >

    <CommonLabel
      v-if="
        changes.showSeparator && changes.details && changes.additionalDetails
      "
      class="text-gray-100 dark:text-neutral-400"
      :class="{
        'ltr:mr-1 rtl:ml-1': changes.details || changes.additionalDetails,
      }"
      >→</CommonLabel
    >

    <CommonLabel
      v-if="changes.additionalDetails"
      class="cursor-text rounded bg-neutral-200 px-0.5 font-mono text-black dark:bg-gray-400 dark:text-white"
      >{{ changes.additionalDetails }}</CommonLabel
    >
  </span>
</template>
