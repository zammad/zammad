<!-- Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/ -->

<script setup lang="ts">
import type { ImageToolbarAction } from '#shared/components/Form/fields/FieldEditor/features/image-handler/types.ts'

defineProps<{
  actions: ImageToolbarAction[]
}>()
</script>

<template>
  <div
    class="flex gap-1.5 rounded-xl border border-blue-200 bg-neutral-50 p-1 dark:border-gray-700 dark:bg-gray-500"
  >
    <template v-for="action in actions" :key="action.key">
      <button
        v-tooltip="$t(action.label)"
        type="button"
        class="flex items-center rounded-lg p-1.5 focus-visible-app-default transition-colors hover:bg-blue-600 hover:text-contrast active:bg-blue-800! active:text-white aria-expanded:bg-blue-800! aria-expanded:text-white dark:hover:bg-blue-900"
        :class="{ 'text-red-500': action.variant === 'danger' }"
        :aria-label="$t(action.label)"
        v-bind="action.attrs"
        @click="action.onClick"
      >
        <CommonIcon :name="action.icon" size="tiny" decorative />
      </button>
      <!-- Not an `hr`: the toolbar is rendered within the editor content, which styles its rules. -->
      <div
        v-if="action.showDivider"
        role="separator"
        aria-orientation="vertical"
        class="w-px self-stretch bg-neutral-700 dark:bg-neutral-800"
      />
    </template>
  </div>
</template>
