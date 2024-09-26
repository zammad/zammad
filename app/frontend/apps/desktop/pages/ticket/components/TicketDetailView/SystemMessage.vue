<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import ArticleReactionBadge from './ArticleReactionBadge.vue'

interface Props {
  subject: string
  to?: Maybe<string>
  reaction?: Maybe<string>
}

defineProps<Props>()
</script>

<template>
  <div
    class="relative rounded-lg border border-current p-3 text-center text-neutral-500"
  >
    <CommonLabel>&quot;{{ subject }}&quot;</CommonLabel>
    <template v-if="to">
      -&gt;
      <CommonLabel>&quot;{{ to }}&quot;</CommonLabel>
    </template>

    <ArticleReactionBadge position="system" :reaction="reaction" />
  </div>
</template>
