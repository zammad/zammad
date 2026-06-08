<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref } from 'vue'

import { useArticleSeen } from '../../composable/useArticleSeen.ts'

import ArticleReactionBadge from './ArticleReactionBadge.vue'

interface Props {
  subject?: Maybe<string>
  to?: Maybe<string>
  reaction?: Maybe<string>
}

defineProps<Props>()

const emit = defineEmits<{
  seen: []
}>()

const articleElement = ref<HTMLDivElement>()

useArticleSeen(articleElement, emit)
</script>

<template>
  <div ref="articleElement" class="flex items-center gap-2 text-gray">
    <div class="grow text-center">"{{ subject }}" -&gt; "{{ to }}"</div>
    <ArticleReactionBadge
      v-if="reaction"
      class="w-7 border border-black bg-blue text-black"
      :reaction="reaction"
    />
  </div>
</template>
