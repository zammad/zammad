<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

import type { TicketArticle } from '#shared/entities/ticket/types.ts'

import ArticleBubbleMetaFields from '#desktop/pages/ticket/components/TicketDetailView/ArticleBubble/ArticleBubbleMetaFields.vue'

interface Props {
  article: TicketArticle
  position: 'left' | 'right'
}

const props = defineProps<Props>()

const metaFieldContainerClasses = computed(() =>
  props.position === 'right'
    ? ['dark:bg-stone-700', 'bg-blue-300']
    : ['dark:bg-gray-500', 'bg-neutral-50'],
)
</script>

<template>
  <header
    :class="metaFieldContainerClasses"
    :aria-label="$t('Article meta information')"
  >
    <ArticleBubbleMetaFields :article="article" class="px-6 py-3" />
  </header>
</template>
