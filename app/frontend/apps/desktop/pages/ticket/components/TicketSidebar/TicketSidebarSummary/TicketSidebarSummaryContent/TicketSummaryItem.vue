<!-- Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { computed } from 'vue'

interface Props {
  summary: string | string[]
  label: string
  variant?: 'ai'
}

const props = defineProps<Props>()

const variantClass = computed(() =>
  props.variant ? ['ai-stripe before:h-[1px] before:mb-3'] : [],
)
</script>

<template>
  <div class="flex flex-col" :class="variantClass">
    <CommonLabel class="mb-3 block! text-black! dark:text-white!" tag="h3">{{
      $t(label)
    }}</CommonLabel>
    <ol
      v-if="Array.isArray(summary)"
      class="space-y-3 text-gray-100 dark:text-neutral-400"
    >
      <li
        v-for="content in summary"
        :key="content"
        class="grid grid-cols-[min-content_1fr] gap-x-2 gap-y-1 ps-2 before:col-start-1 before:mt-2 before:h-[3px] before:w-[3px] before:shrink-0 before:rounded-full before:bg-current"
      >
        <CommonLabel class="col-2" tag="p">{{ content }}</CommonLabel>

        <slot name="item-trailing" :content="content" />
      </li>
    </ol>
    <CommonLabel v-else tag="p">{{ summary }}</CommonLabel>
    <slot name="trailing" />
  </div>
</template>
