<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import CommonSkeleton from '#desktop/components/CommonSkeleton/CommonSkeleton.vue'

import {
  CATEGORY_GRID_CLASSES,
  CATEGORY_GRID_REVEAL,
} from '../../utils/knowledgeBaseCategoryGrid.ts'

import type { KnowledgeBaseContentScope } from '../../types.ts'

withDefaults(
  defineProps<{
    count?: number
    // Which shape to stand in for: the answers are a list, the categories a card grid. Not
    //   KnowledgeBaseCategoryCardSkeleton for the latter - that one draws the *browse* card, with
    //   the divider and the count badges a search result does not have.
    scope?: KnowledgeBaseContentScope
  }>(),
  {
    count: 3,
    scope: 'answers',
  },
)

const titleWidths = ['w-1/3', 'w-1/2', 'w-2/5', 'w-3/5', 'w-1/4']
</script>

<template>
  <!-- w-full: the loader centers its skeleton in a flex column, where a bare grid would
       otherwise shrink to its content width. -->
  <ol
    v-if="scope === 'categories'"
    :class="CATEGORY_GRID_CLASSES"
    class="w-full"
    aria-hidden="true"
  >
    <li
      v-for="index in count"
      :key="index"
      class="flex min-h-32 flex-col items-center gap-3 rounded-xl bg-blue-200 px-3 py-4 dark:bg-gray-500"
      :class="CATEGORY_GRID_REVEAL[index as keyof typeof CATEGORY_GRID_REVEAL]"
    >
      <CommonSkeleton class="size-8" rounded alternative-background />
      <CommonSkeleton
        class="h-3.5"
        :class="titleWidths[(index - 1) % titleWidths.length]"
        :style="{ 'animation-delay': '0.1s' }"
        alternative-background
      />
      <CommonSkeleton
        class="h-3 w-1/2"
        :style="{ 'animation-delay': '0.2s' }"
        alternative-background
      />
    </li>
  </ol>

  <ol v-else class="flex flex-col gap-4" aria-hidden="true">
    <li
      v-for="index in count"
      :key="index"
      class="flex items-start gap-3 rounded-xl bg-blue-200 px-3 py-2.5 dark:bg-gray-500"
    >
      <CommonSkeleton class="size-8" alternative-background />
      <div
        class="flex grow flex-col gap-2 py-1"
        :style="{ 'animation-delay': `${((index - 1) % 3) * 0.1}s` }"
      >
        <CommonSkeleton
          class="h-3.5"
          :class="titleWidths[(index - 1) % titleWidths.length]"
          alternative-background
        />
        <CommonSkeleton class="h-3 w-4/5" alternative-background />
        <CommonSkeleton class="h-3 w-1/4" alternative-background />
      </div>
    </li>
  </ol>
</template>
