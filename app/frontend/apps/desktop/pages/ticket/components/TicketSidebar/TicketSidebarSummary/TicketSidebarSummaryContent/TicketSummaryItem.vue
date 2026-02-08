<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import { textToHtml } from '#shared/utils/helpers.ts'

interface Props {
  summary: string | string[]
  label: string
  type?: 'list' | 'paragraphs'
}

defineProps<Props>()
</script>

<template>
  <div class="flex flex-col">
    <CommonLabel class="mb-3 block! text-black! dark:text-white!" tag="h3">{{
      $t(label)
    }}</CommonLabel>
    <ol
      v-if="type === 'list' && Array.isArray(summary)"
      class="space-y-3 text-gray-100 dark:text-neutral-400"
    >
      <li
        v-for="content in summary"
        :key="content"
        class="grid grid-cols-[min-content_1fr] gap-x-2 gap-y-1 ps-2 before:col-start-1 before:mt-2 before:h-[3px] before:w-[3px] before:shrink-0 before:rounded-full before:bg-current"
      >
        <!-- eslint-disable-next-line vue/no-v-text-v-html-on-component, vue/no-v-html -->
        <CommonLabel class="col-2" tag="p" v-html="textToHtml(content)" />

        <slot name="item-trailing" :content="content" />
      </li>
    </ol>
    <div v-else-if="type === 'paragraphs' && Array.isArray(summary)" class="space-y-2">
      <CommonLabel v-for="content in summary" :key="content" class="block!" tag="p">{{
        content
      }}</CommonLabel>
    </div>
    <CommonLabel v-else class="block!" tag="p">{{ summary }}</CommonLabel>
    <slot name="trailing" />
  </div>
</template>
