<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref } from 'vue'
import { useArticleSeen } from '../../composable/useArticleSeen.ts'

interface Props {
  subject?: Maybe<string>
  to?: Maybe<string>
}

defineProps<Props>()

const emit = defineEmits<{
  (e: 'seen'): void
}>()

const articleElement = ref<HTMLDivElement>()

useArticleSeen(articleElement, emit)
</script>

<template>
  <div ref="articleElement" class="text-center text-gray">
    "{{ subject }}" -&gt; "{{ to }}"
  </div>
</template>
