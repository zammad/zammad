<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { HighlightSegment } from './types.ts'

interface Props {
  // Renders pre-split segments rather than raw search-engine markup: the server hands over
  //   plain text runs with a flag, so nothing here ever reaches `v-html`.
  segments: HighlightSegment[]
}
defineProps<Props>()
</script>

<template>
  <template v-for="(segment, index) in segments" :key="index">
    <mark
      v-if="segment.highlight"
      class="bg-(--article-highlight-blue) text-black dark:text-white"
      >{{ segment.text }}</mark
    >
    <template v-else>{{ segment.text }}</template>
  </template>
</template>
