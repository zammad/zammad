<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'

import KnowledgeBaseAnswerCardSkeleton from './KnowledgeBaseAnswerCardSkeleton.vue'

interface Props {
  count?: number
  // Skeletons the add-answer entry point too, so it does not pop in after the list has rendered.
  withAddAnswer?: boolean
}

withDefaults(defineProps<Props>(), {
  count: 3,
})
</script>

<template>
  <ol class="mt-4 flex flex-col gap-4">
    <KnowledgeBaseAnswerCardSkeleton v-for="i in count" :key="i" :index="i" />

    <li
      v-if="withAddAnswer"
      class="flex h-12.5 items-center justify-center rounded-xl bg-blue-200 px-3 dark:bg-gray-500"
    >
      <CommonSkeleton class="h-8 w-32 rounded-lg" />
    </li>
  </ol>
</template>
