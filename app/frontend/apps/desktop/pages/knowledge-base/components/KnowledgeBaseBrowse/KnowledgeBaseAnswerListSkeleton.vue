<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'

import KnowledgeBaseAnswerCardSkeleton from './KnowledgeBaseAnswerCardSkeleton.vue'

interface Props {
  // How many answers are on their way, when that is known before they arrive - the count the
  //   category carries at its own level. A count of none is not known: this is only ever on screen
  //   while the listing is still being fetched, so nothing to lay out means nothing is known yet -
  //   and a skeleton that lays out nothing does not say that something is coming, which is its
  //   whole job.
  count?: number
  // The rows one request can bring, which is what the count is capped at: a category of hundreds
  //   would otherwise lay out hundreds of rows for a first page of thirty.
  pageSize?: number
  // Skeletons the add-answer entry point too, so it does not pop in after the list has rendered.
  withAddAnswer?: boolean
}

const props = defineProps<Props>()

// With no count in reach, enough rows to read as a list without filling the page.
const ROW_GUESS = 3

const rowCount = computed(() => {
  if (!props.count || props.count <= 0) return ROW_GUESS

  return props.pageSize ? Math.min(props.count, props.pageSize) : props.count
})
</script>

<template>
  <ol class="mt-4 flex flex-col gap-4">
    <KnowledgeBaseAnswerCardSkeleton v-for="i in rowCount" :key="i" :index="i" />

    <li
      v-if="withAddAnswer"
      class="flex h-12.5 items-center justify-center rounded-xl bg-blue-200 px-3 dark:bg-gray-500"
    >
      <CommonSkeleton class="h-8 w-32 rounded-lg" />
    </li>
  </ol>
</template>
