<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import KnowledgeBaseAnswerCardSkeleton from './KnowledgeBaseAnswerCardSkeleton.vue'

interface Props {
  count?: number
}

withDefaults(defineProps<Props>(), {
  count: 3,
})
</script>

<template>
  <ol class="mt-4 flex flex-col gap-4">
    <KnowledgeBaseAnswerCardSkeleton v-for="i in count" :key="i" :index="i" />
  </ol>
</template>
