<!-- Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { ref } from 'vue'
import { useArticleSeen } from '../../composable/useArticleSeen.ts'

defineProps<{
  content: string
  gap: 'small' | 'big'
}>()

const emit = defineEmits<{
  (e: 'seen'): void
}>()

const articleElement = ref<HTMLDivElement>()

useArticleSeen(articleElement, emit)
</script>

<template>
  <div ref="articleElement" class="flex justify-center">
    <div
      :class="{ 'mt-6': gap === 'big', 'mt-2': gap === 'small' }"
      class="flex flex-col items-center rounded-3xl border border-yellow bg-yellow-highlight p-4 text-yellow"
    >
      <div
        class="absolute flex h-7 w-7 -translate-y-7 items-center justify-center rounded-full bg-yellow text-black"
      >
        <CommonIcon name="mobile-warning" size="small" />
      </div>
      <div>{{ $t('Delivery failed:') }} "{{ content }}"</div>
    </div>
  </div>
</template>
